#
# Cookbook Name:: delivery-cluster
# Recipe:: setup
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

require 'chef/provisioning/aws_driver'

with_driver 'aws'

with_machine_options ({
    :bootstrap_options => {
      :instance_type      => node['delivery-cluster']['aws']['flavor'],
      :key_name           => node['delivery-cluster']['aws']['key_name'],
      :security_group_ids => node['delivery-cluster']['aws']['security_group_ids']
    },
    :ssh_username => node['delivery-cluster']['aws']['ssh_username'],
    :image_id     => node['delivery-cluster']['aws']['image_id']
  })

add_machine_options bootstrap_options: { :subnet_id => node['delivery-cluster']['aws']['subnet_id'] } if node['delivery-cluster']['aws']['subnet_id']
add_machine_options use_private_ip_for_ssh: node['delivery-cluster']['aws']['use_private_ip_for_ssh'] if node['delivery-cluster']['aws']['use_private_ip_for_ssh']

# Pre-requisits
# => Builder Keys
execute "Creating Builder Keys" do
  command <<-EOM.gsub(/\s+/, " ").strip!
    openssl genrsa -out #{tmp_infra_dir}/builder_key 2048;
    chmod 600 #{tmp_infra_dir}/builder_key && ssh-keygen -y -f #{tmp_infra_dir}/builder_key > #{tmp_infra_dir}/builder_key.pub
  EOM
  creates "#{tmp_infra_dir}/builder_key.pub"
  action :nothing
end.run_action(:run)

# => Encrypted Secret Key
execute "Creating Encrypted Secret Key" do
  command "openssl rand -base64 512 > #{tmp_infra_dir}/encrypted_data_bag_secret"
  creates "#{tmp_infra_dir}/encrypted_data_bag_secret"
  action :run
end

# First thing we do is create the chef-server EMPTY so
# we can get the PublicIP that we will use in constantly
machine node['delivery-cluster']['chef-server']['hostname'] do
  add_machine_options bootstrap_options: { instance_type: node['delivery-cluster']['chef-server']['flavor'] } if node['delivery-cluster']['chef-server']['flavor']
  action :nothing
end.run_action(:converge)

# Kinda feeling this could be an API
# We extract the ip and then install chef-server using the PublicIP
chef_node = Chef::Node.load(node['delivery-cluster']['chef-server']['hostname'])
chef_server_ip = chef_node['ec2']['public_ipv4']
Chef::Log.info("Your Chef Server Public IP is => #{chef_server_ip}")

# Installing Chef Server
machine node['delivery-cluster']['chef-server']['hostname'] do
  recipe "chef-server-12"
  attributes 'chef-server-12' => {
    'delivery' => { 'organization' => node['delivery-cluster']['chef-server']['organization'] },
    'api_fqdn' => chef_server_ip,
    'store_keys_databag' => false
  }
  action :nothing
end.run_action(:converge)

# Getting the keys from chef-server
machine_file "/tmp/validator.pem" do
  machine node['delivery-cluster']['chef-server']['hostname']
  local_path "#{tmp_infra_dir}/validator.pem"
  action :nothing
end.run_action(:download)

machine_file "/tmp/delivery.pem" do
  machine node['delivery-cluster']['chef-server']['hostname']
  local_path "#{tmp_infra_dir}/delivery.pem"
  action :nothing
end.run_action(:download)

machine_file "/var/opt/opscode/nginx/ca/#{chef_server_ip}.crt" do
  machine node['delivery-cluster']['chef-server']['hostname']
  local_path "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_ip}.crt"
  action :nothing
end.run_action(:download)

# Shortcut
new_chef_server_url = "https://#{chef_server_ip}/organizations/#{node['delivery-cluster']['chef-server']['organization']}"

# Setting the new Chef Server we just created
with_chef_server new_chef_server_url,
  :client_name => "delivery",
  :signing_key_filename => "#{tmp_infra_dir}/delivery.pem"

Chef::Config.node_name        = 'delivery'
Chef::Config.client_key       = "#{tmp_infra_dir}/delivery.pem"
Chef::Config.chef_server_url  = new_chef_server_url

# Creating the Data Bag that store some Key Dependencies
chef_data_bag "keys" do
  action :create # see actions section below
end

chef_data_bag_item "keys/delivery_builder_keys" do
  raw_data ({
      'id' => "delivery_builder_keys",
      'builder_key' => File.read("#{tmp_infra_dir}/builder_key.pub"),
      'delivery_pem' => File.read("#{tmp_infra_dir}/delivery.pem")
    })
  secret_path "#{tmp_infra_dir}/encrypted_data_bag_secret"
  encryption_version 1
  encrypt true
  action :create
end

# Cheffish to upload cookbook dependencies
# NOT WORKING!!
# TODO: Fix it and then implement it
# chef_mirror 'cookbooks/*' do
#   chef_repo_path cookbook_path: File.join(current_dir, 'cookbooks')
#   action :nothing
# end.run_action(:upload)

directory dot_chef_dir do
  action :create
end

file File.join(dot_chef_dir, '.chef', 'knife.rb') do
  content <<-EOH
current_chef_dir = File.dirname(__FILE__)
working_dir      = Dir.pwd
cookbook_paths   = []
cookbook_paths  << File.join(current_chef_dir, '..','vendor/cookbooks')

node_name        'delivery'
chef_server_url  '#{new_chef_server_url}'
client_key       '#{tmp_infra_dir}/delivery.pem'
coobkook_path    cookbook_paths
  EOH
end

execute "upload delivery cookbooks" do
  cwd current_dir
  command "berks upload"
end

# Now that we are ready to Install Delivery and the build nodes
# we really need to get the PublicIP again to configure `delivery.rb`
# therefore this batch machines.
machine_batch "Provisioning Delivery Infrastructure" do
  # Creating Delivery Server
  machine node['delivery-cluster']['delivery']['hostname'] do
    add_machine_options bootstrap_options: { instance_type: node['delivery-cluster']['delivery']['flavor']  } if node['delivery-cluster']['delivery']['flavor']
  end
  # Creating Build Nodes
  1.upto(node['delivery-cluster']['builders']['N']) do |i|
    machine "#{node['delivery-cluster']['builders']['hostname']}-#{i}" do
      add_machine_options bootstrap_options: { instance_type: node['delivery-cluster']['builders']['flavor']  } if node['delivery-cluster']['builders']['flavor']
    end
  end
  action :nothing
end.run_action(:converge)

# Now it is time to get the PublicIP and use it to install Delivery
deliv_node = Chef::Node.load(node['delivery-cluster']['delivery']['hostname'])
deliv_ip   = deliv_node['ec2']['public_ipv4']
Chef::Log.info("Your Delivery Server Public IP is => #{deliv_ip}")

# If we don't have the artifact, we will get it from artifactory
# We will need VPN to do so. Or other way could be to upload it
# to S3 bucket automatically
#
# Get the latest artifact:
# => artifact = get_delivery_artifact('latest', 'redhat', '6.5')
#
# Get specific artifact:
# => artifact = get_delivery_artifact('0.2.21', 'ubuntu', '12.04', '/var/tmp')
#
if node['delivery-cluster']['delivery'][deliv_node['platform_family']] && node['delivery-cluster']['delivery']['version'] != 'latest'
  # We use the provided artifact
  deliv_version = node['delivery-cluster']['delivery']['version']

  delivery_artifact = {
    deliv_node['platform_family'] => {
      "artifact" => node['delivery-cluster']['delivery'][deliv_node['platform_family']]['artifact'],
      "checksum" => node['delivery-cluster']['delivery'][deliv_node['platform_family']]['checksum']
    }
  }
else
  # We will get it from artifactory
  artifact = get_delivery_artifact(node['delivery-cluster']['delivery']['version'], deliv_node['platform'], deliv_node['platform_version'], tmp_infra_dir)

  deliv_version = artifact['version']

  # Upload Artifact to Delivery Server
  machine_file "/var/tmp/#{artifact['name']}" do
    machine node['delivery-cluster']['delivery']['hostname']
    local_path  artifact['local_path']
    action :upload
  end

  delivery_artifact = {
    deliv_node['platform_family'] => {
      "artifact" => "/var/tmp/#{artifact['name']}",
      "checksum" => artifact['checksum']
    }
  }
end

# Creating the Data Bag that store the Delivery Artifacts
chef_data_bag "delivery" do
  action :create # see actions section below
end
chef_data_bag_item "delivery/#{deliv_version}" do
  raw_data ({
    "id"       => deliv_version,
    "version"  => deliv_version,
    "platforms" => delivery_artifact
  })
  action :create
end

# Creating Delivery Builder Role
chef_role node['delivery-cluster']['builders']['role'] do
  description "Base Role for the Delivery Build Nodes"
  run_list ["recipe[push-jobs]","recipe[delivery_builder]"]
end

delivery_attributes = {
  'applications' => { 'delivery' => deliv_version },
  'delivery'     => {
    'chef_server' => new_chef_server_url,
    'fqdn' => deliv_ip
  }
}

# Add LDAP config if it exist
delivery_attributes['delivery']['ldap'] = node['delivery_cluster']['delivery']['ldap'] unless node['delivery_cluster']['delivery']['ldap'].empty?

# Install Delivery
machine node['delivery-cluster']['delivery']['hostname'] do
  # chef_environment environment
  recipe "delivery-server"
  converge true
  files ({
    '/etc/delivery/delivery.pem' => "#{tmp_infra_dir}/delivery.pem",
    '/etc/delivery/builder_key' => "#{tmp_infra_dir}/builder_key",
    '/etc/delivery/builder_key.pub' => "#{tmp_infra_dir}/builder_key.pub"
  })
  attributes delivery_attributes
  action :converge
end

# Creating Your Enterprise
machine_execute "Creating Enterprise" do
  command <<-EOM.gsub(/\s+/, " ").strip!
    #{delivery_ctl} list-enterprises | grep -w ^#{node['delivery-cluster']['delivery']['enterprise']};
    [ $? -ne 0 ] && #{delivery_ctl} create-enterprise #{node['delivery-cluster']['delivery']['enterprise']} > /tmp/#{node['delivery-cluster']['delivery']['enterprise']}.creds || echo 1
  EOM
  machine node['delivery-cluster']['delivery']['hostname']
end

# Downloading Creds
machine_file "/tmp/#{node['delivery-cluster']['delivery']['enterprise']}.creds" do
  machine node['delivery-cluster']['delivery']['hostname']
  local_path "#{tmp_infra_dir}/#{node['delivery-cluster']['delivery']['enterprise']}.creds"
  action :download
end

# Preparing Build Nodes with the right run_list
machine_batch "#{node['delivery-cluster']['builders']['count']}-build-nodes" do
  1.upto(node['delivery-cluster']['builders']['count']) do |i|
    machine "#{node['delivery-cluster']['builders']['hostname_prefix']}-#{i}" do
      role node['delivery-cluster']['builders']['role']
      add_machine_options convergence_options: { :chef_config_text => "encrypted_data_bag_secret File.join(File.dirname(__FILE__), 'encrypted_data_bag_secret')" }
      files '/etc/chef/encrypted_data_bag_secret' => "#{tmp_infra_dir}/encrypted_data_bag_secret"
      action :converge
    end
  end
end

# Might be cool to print the enterprise admin user at the end
ruby_block "Delayed Print" do
  block do
    system "cat #{tmp_infra_dir}/#{node['delivery-cluster']['delivery']['enterprise']}.creds"
  end
end
