#
# Cookbook Name:: delivery-cluster
# Recipe:: setup
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

require 'openssl'
require 'chef/provisioning/aws_driver'

with_driver 'aws'

with_machine_options(
  bootstrap_options: {
    instance_type: node['delivery-cluster']['aws']['flavor'],
    key_name: node['delivery-cluster']['aws']['key_name'],
    security_group_ids: node['delivery-cluster']['aws']['security_group_ids']
  },
  ssh_username: node['delivery-cluster']['aws']['ssh_username'],
  image_id:     node['delivery-cluster']['aws']['image_id']
)

add_machine_options bootstrap_options: { subnet_id: node['delivery-cluster']['aws']['subnet_id'] } if node['delivery-cluster']['aws']['subnet_id']
add_machine_options use_private_ip_for_ssh: node['delivery-cluster']['aws']['use_private_ip_for_ssh'] if node['delivery-cluster']['aws']['use_private_ip_for_ssh']

# Force a save of node data
node.save

directory tmp_infra_dir do
  action :create
end

# Pre-requisits
# => Builder Keys
file "#{tmp_infra_dir}/builder_key.pub" do
  mode    '0644'
  content builder_key.public_key.to_s
  sensitive true
  action :create
end

file "#{tmp_infra_dir}/builder_key" do
  mode    '0600'
  content builder_key.to_pem.to_s
  sensitive true
  action :create
end

# => Encrypted Secret Key
execute "Creating Encrypted Secret Key" do
  command "openssl rand -base64 512 > #{tmp_infra_dir}/encrypted_data_bag_secret"
  creates "#{tmp_infra_dir}/encrypted_data_bag_secret"
  action :run
end

# First thing we do is create the chef-server EMPTY so
# we can get the PublicIP that we will use in constantly
machine chef_server_hostname do
  add_machine_options bootstrap_options: { instance_type: node['delivery-cluster']['chef-server']['flavor'] } if node['delivery-cluster']['chef-server']['flavor']
  action :converge
end

# Installing Chef Server
machine chef_server_hostname do
  recipe "chef-server-12"
  attributes lazy { chef_server_attributes }
  action :converge
end

# Getting the keys from chef-server
machine_file "/tmp/validator.pem" do
  machine chef_server_hostname
  local_path "#{tmp_infra_dir}/validator.pem"
  action :download
end

machine_file "/tmp/delivery.pem" do
  machine chef_server_hostname
  local_path "#{tmp_infra_dir}/delivery.pem"
  action :download
end

# machine_file "/var/opt/opscode/nginx/ca/#{chef_server_ip}.crt" do
#   machine node['delivery-cluster']['chef-server']['hostname']
#   local_path lazy { "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_ip}.crt" }
#   action :download
# end

# Setting the new Chef Server we just created
ruby_block 'updated Chef config' do
  block do
    # TODO: find a better way!
    run_context.cheffish.with_chef_server(
      chef_server_url: chef_server_url,
      options: {
        client_name: "delivery",
        signing_key_filename: "#{tmp_infra_dir}/delivery.pem"
      }
    )

    Chef::Config.node_name        = 'delivery'
    Chef::Config.client_key       = "#{tmp_infra_dir}/delivery.pem"
    Chef::Config.chef_server_url  = chef_server_url
  end
end

# Creating the Data Bag that store some Key Dependencies
chef_data_bag "keys" do
  action :create # see actions section below
end

chef_data_bag_item "keys/delivery_builder_keys" do
  raw_data(
    'id' => "delivery_builder_keys",
    'builder_key' => builder_key.public_key.to_s,
    'delivery_pem' => builder_key.to_pem.to_s
  )
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

file File.join(tmp_infra_dir, 'knife.rb') do
  content lazy { <<-EOH
current_chef_dir = File.dirname(__FILE__)
working_dir      = Dir.pwd
cookbook_paths   = []
cookbook_paths  << File.join(current_chef_dir, '..','cookbooks')
cookbook_paths  << File.join(current_chef_dir, '..','vendor/cookbooks')

node_name        'delivery'
chef_server_url  '#{chef_server_url}'
client_key       '#{tmp_infra_dir}/delivery.pem'
cookbook_path    cookbook_paths
  EOH
  }
end

execute "upload delivery cookbooks" do
  cwd current_dir
  command "berks upload"
  environment(
    'BERKSHELF_CHEF_CONFIG' => "#{tmp_infra_dir}/knife.rb"
  )
end

# Now that we are ready to Install Delivery and the build nodes
# we really need to get the PublicIP again to configure `delivery.rb`
# therefore this batch machines.
machine_batch "Provisioning Delivery Infrastructure" do
  # Creating Delivery Server
  machine delivery_server_hostname do
    add_machine_options bootstrap_options: { instance_type: node['delivery-cluster']['delivery']['flavor']  } if node['delivery-cluster']['delivery']['flavor']
  end
  # Creating Build Nodes
  1.upto(node['delivery-cluster']['builders']['count']) do |i|
    machine delivery_builder_hostname(i) do
      add_machine_options bootstrap_options: { instance_type: node['delivery-cluster']['builders']['flavor']  } if node['delivery-cluster']['builders']['flavor']
    end
  end
  action :converge
end

# Creating the Data Bag that store the Delivery Artifacts
ruby_block '' do
  block do
    chef_data_bag "delivery" do
      action :create # see actions section below
    end
    chef_data_bag_item "delivery/#{delivery_server_version}" do
      raw_data(
        "id"       => delivery_server_version,
        "version"  => delivery_server_version,
        "platforms" => delivery_artifact
      )
      action :create
    end
  end
end

# Creating Delivery Builder Role
chef_role node['delivery-cluster']['builders']['role'] do
  description "Base Role for the Delivery Build Nodes"
  run_list ["recipe[push-jobs]","recipe[delivery_builder]"]
end

# Install Delivery
machine delivery_server_hostname do
  # chef_environment environment
  recipe "delivery-server"
  converge true
  files(
    '/etc/delivery/delivery.pem' => "#{tmp_infra_dir}/delivery.pem",
    '/etc/delivery/builder_key' => "#{tmp_infra_dir}/builder_key",
    '/etc/delivery/builder_key.pub' => "#{tmp_infra_dir}/builder_key.pub"
  )
  attributes lazy { delivery_attributes }
  action :converge
end

# Creating Your Enterprise
machine_execute "Creating Enterprise" do
  command <<-EOM.gsub(/\s+/, " ").strip!
    #{delivery_ctl} list-enterprises | grep -w ^#{node['delivery-cluster']['delivery']['enterprise']};
    [ $? -ne 0 ] && #{delivery_ctl} create-enterprise #{node['delivery-cluster']['delivery']['enterprise']} > /tmp/#{node['delivery-cluster']['delivery']['enterprise']}.creds || echo 1
  EOM
  machine delivery_server_hostname
end

# Downloading Creds
machine_file "/tmp/#{node['delivery-cluster']['delivery']['enterprise']}.creds" do
  machine delivery_server_hostname
  local_path "#{tmp_infra_dir}/#{node['delivery-cluster']['delivery']['enterprise']}.creds"
  action :download
end

# Preparing Build Nodes with the right run_list
machine_batch "#{node['delivery-cluster']['builders']['count']}-build-nodes" do
  1.upto(node['delivery-cluster']['builders']['count']) do |i|
    machine delivery_builder_hostname(i) do
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
