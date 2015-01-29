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

################################################################################
# Phase 1: Bootstrap a Chef Server instance with Chef-Zero
################################################################################

# It's ugly but this must happen in the compile phase so we can switch out
# the Chef Server we are talking to for the remainder of the CCR.

# Provision the Chef Server with an empty runlist so we can extract
# it's primary ipaddress to use as the hostname in the initial
# `/etc/opscode/chef-server.rb` file
machine chef_server_hostname do
  add_machine_options bootstrap_options: { instance_type: node['delivery-cluster']['chef-server']['flavor'] } if node['delivery-cluster']['chef-server']['flavor']
  action :nothing
end.run_action(:converge)

# Now that we've extracted the Chef Server's ipaddress we can fully
# converge and complete the install.
machine chef_server_hostname do
  recipe "chef-server-12"
  attributes chef_server_attributes
  action :nothing
end.run_action(:converge)

directory tmp_infra_dir do
  action :nothing
end.run_action(:create)

directory Chef::Config[:trusted_certs_dir] do
  action :nothing
end.run_action(:create)

# Fetch our client and validator pems from the provisioned Chef Server
machine_file "/tmp/validator.pem" do
  machine chef_server_hostname
  local_path "#{tmp_infra_dir}/validator.pem"
  action :nothing
end.run_action(:download)

machine_file "/tmp/delivery.pem" do
  machine chef_server_hostname
  local_path "#{tmp_infra_dir}/delivery.pem"
  action :nothing
end.run_action(:download)

machine_file "/var/opt/opscode/nginx/ca/#{chef_server_ip}.crt" do
  machine chef_server_hostname
  local_path "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_ip}.crt"
  action :nothing
end.run_action(:download)

# Point the local, in-progress CCR along with all remote CCRs at the freshly
# provisioned Chef Server
with_chef_server chef_server_url,
  client_name: 'delivery',
  signing_key_filename: "#{tmp_infra_dir}/delivery.pem"

Chef::Config.node_name        = 'delivery'
Chef::Config.client_key       = "#{tmp_infra_dir}/delivery.pem"
Chef::Config.chef_server_url  = chef_server_url

################################################################################
# Phase 2: Bootstrap the rest of our infrastructure with the new Chef Server
################################################################################

# create an encrypted data bag secret
file "#{tmp_infra_dir}/encrypted_data_bag_secret" do
  mode    '0644'
  content encrypted_data_bag_secret
  sensitive true
  action :create
end

# create required builder keys
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

# create the data bag (and item) to store our builder keys
chef_data_bag "keys" do
  action :create
end

chef_data_bag_item "keys/delivery_builder_keys" do
  raw_data(
    delivery_pem: builder_key.to_pem.to_s
    builder_key:  builder_key.to_pem.to_s,
  )
  secret_path "#{tmp_infra_dir}/encrypted_data_bag_secret"
  encryption_version 1
  encrypt true
  action :create
end

# generate a knife config file that points at the new Chef Server
file File.join(tmp_infra_dir, 'knife.rb') do
  content <<-EOH
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
end

execute "upload delivery cookbooks" do
  cwd current_dir
  command "berks upload --no-ssl-verify"
  environment(
    'BERKSHELF_CHEF_CONFIG' => "#{tmp_infra_dir}/knife.rb"
  )
end

# Provision the Delivery server with an empty runlist so we can extract
# it's primary ipaddress to use as the hostname in the initial
# `/etc/opscode/delivery.rb` file
machine delivery_server_hostname do
  add_machine_options bootstrap_options: { instance_type: node['delivery-cluster']['delivery']['flavor']  } if node['delivery-cluster']['delivery']['flavor']
  files(
    "/etc/chef/trusted_certs/#{chef_server_ip}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_ip}.crt"
  )
  action :converge
end

# Creating the Data Bag that store the Delivery Artifacts
chef_data_bag "delivery" do
  action :create
end

# This is ugly but there is no other easy way to set  `chef_data_bag_item`'s
# name attribute lazily
ruby_block 'delivery-versions-data-bag-item' do
  block do
    dbi = Chef::Resource::ChefDataBagItem.new("delivery/#{delivery_server_version}", run_context)
    dbi.raw_data(
      id: delivery_server_version,
      version: delivery_server_version,
      platforms: delivery_artifact
    )
    dbi.run_action(:create)
  end
end

# Now that we've extracted the Delivery Server's ipaddress we can fully
# converge and complete the install.
machine delivery_server_hostname do
  add_machine_options bootstrap_options: { instance_type: node['delivery-cluster']['delivery']['flavor']  } if node['delivery-cluster']['delivery']['flavor']
  recipe "delivery-server"
  files(
    '/etc/delivery/delivery.pem' => "#{tmp_infra_dir}/delivery.pem",
    '/etc/delivery/builder_key' => "#{tmp_infra_dir}/builder_key",
    '/etc/delivery/builder_key.pub' => "#{tmp_infra_dir}/builder_key.pub"
  )
  attributes lazy { delivery_server_attributes }
  action :converge
end

machine_file "/var/opt/delivery/nginx/ca/#{delivery_server_ip}.crt" do
  machine delivery_server_hostname
  local_path "#{Chef::Config[:trusted_certs_dir]}/#{delivery_server_ip}.crt"
  action :download
end

# Create the default Delivery enterprise
machine_execute "Creating Enterprise" do
  command <<-EOM.gsub(/\s+/, " ").strip!
    #{delivery_ctl} list-enterprises | grep -w ^#{node['delivery-cluster']['delivery']['enterprise']};
    [ $? -ne 0 ] && #{delivery_ctl} create-enterprise #{node['delivery-cluster']['delivery']['enterprise']} > /tmp/#{node['delivery-cluster']['delivery']['enterprise']}.creds || echo 1
  EOM
  machine delivery_server_hostname
end

# Download the credentials form the Delivery server
machine_file "/tmp/#{node['delivery-cluster']['delivery']['enterprise']}.creds" do
  machine delivery_server_hostname
  local_path "#{tmp_infra_dir}/#{node['delivery-cluster']['delivery']['enterprise']}.creds"
  action :download
end

#########################################################################
# Create Delivery builders
#########################################################################

# Create the Delivery builder role
chef_role node['delivery-cluster']['builders']['role'] do
  description "Base Role for the Delivery Build Nodes"
  run_list ["recipe[push-jobs]","recipe[delivery_builder]"]
end

# Provision our builders in parallel
machine_batch "#{node['delivery-cluster']['builders']['count']}-build-nodes" do
  1.upto(node['delivery-cluster']['builders']['count']) do |i|
    machine delivery_builder_hostname(i) do
      role node['delivery-cluster']['builders']['role']
      add_machine_options(
        bootstrap_options: {image_id: node['delivery-cluster']['aws']['image_id']},
        convergence_options: { chef_config_text: "encrypted_data_bag_secret File.join(File.dirname(__FILE__), 'encrypted_data_bag_secret')" }
      )
      add_machine_options bootstrap_options: { instance_type: node['delivery-cluster']['builders']['flavor']  } if node['delivery-cluster']['builders']['flavor']
      files(
        "/etc/chef/trusted_certs/#{chef_server_ip}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_ip}.crt",
        "/etc/chef/trusted_certs/#{delivery_server_ip}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{delivery_server_ip}.crt",
        '/etc/chef/encrypted_data_bag_secret' => "#{tmp_infra_dir}/encrypted_data_bag_secret"
      )
      action :converge
    end
  end
end

# Print the generated Delivery server credentials
ruby_block "print-delivery-credentials" do
  block do
    puts File.read("#{tmp_infra_dir}/#{node['delivery-cluster']['delivery']['enterprise']}.creds")
  end
end
