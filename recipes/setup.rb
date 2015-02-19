#
# Cookbook Name:: delivery-cluster
# Recipe:: setup
#
# Author:: Salim Afiune (<afiune@chef.io>)
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
  # Transfer any trusted certs from the current CCR
  Dir.glob("#{Chef::Config[:trusted_certs_dir]}/*.{crt,pem}").each do |cert_path|
    file cert_path, cert_path
  end
  action :converge
end

# Now that we've extracted the Chef Server's ipaddress we can fully
# converge and complete the install.
machine chef_server_hostname do
  recipe "chef-server-12"
  attributes lazy { chef_server_attributes }
  action :converge
end

directory tmp_infra_dir do
  action :create
end

directory Chef::Config[:trusted_certs_dir] do
  action :create
end

# Fetch our client and validator pems from the provisioned Chef Server
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

machine_file 'chef-server-cert' do
  path lazy { "/var/opt/opscode/nginx/ca/#{chef_server_ip}.crt" }
  machine chef_server_hostname
  local_path lazy { "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_ip}.crt" }
  action :download
end

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
  content builder_public_key
  sensitive true
  action :create
end

file "#{tmp_infra_dir}/builder_key" do
  mode    '0600'
  content builder_private_key
  sensitive true
  action :create
end

# create the data bag (and item) to store our builder keys
chef_data_bag "keys" do
  chef_server lazy { chef_server_config }
  action :create
end

chef_data_bag_item "keys/delivery_builder_keys" do
  chef_server lazy { chef_server_config }
  raw_data lazy {{
    builder_key:  builder_private_key,
    delivery_pem: File.read("#{tmp_infra_dir}/delivery.pem")
  }}
  secret_path "#{tmp_infra_dir}/encrypted_data_bag_secret"
  encryption_version 1
  encrypt true
  action :create
end

# generate a knife config file that points at the new Chef Server
file File.join(tmp_infra_dir, 'knife.rb') do
  content lazy {
    <<-EOH
node_name         'delivery'
chef_server_url   '#{chef_server_url}'
client_key        '#{tmp_infra_dir}/delivery.pem'
cookbook_path     '#{Chef::Config[:cookbook_path]}'
trusted_certs_dir '#{Chef::Config[:trusted_certs_dir]}'
    EOH
  }
end

execute "upload delivery cookbooks" do
  command "knife cookbook upload --all --cookbook-path #{Chef::Config[:cookbook_path]}"
  environment(
    'KNIFE_HOME' => tmp_infra_dir
  )
end

# Provision the Delivery server with an empty runlist so we can extract
# it's primary ipaddress to use as the hostname in the initial
# `/etc/opscode/delivery.rb` file
machine delivery_server_hostname do
  chef_server lazy { chef_server_config }
  add_machine_options bootstrap_options: { instance_type: node['delivery-cluster']['delivery']['flavor']  } if node['delivery-cluster']['delivery']['flavor']
  files lazy {{
    "/etc/chef/trusted_certs/#{chef_server_ip}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_ip}.crt"
  }}
  action :converge
end

# Creating the Data Bag that store the Delivery Artifacts
chef_data_bag "delivery" do
  chef_server lazy { chef_server_config }
  action :create
end

# This is ugly but there is no other easy way to set `chef_data_bag_item`'s
# name attribute lazily
ruby_block 'delivery-versions-data-bag-item' do
  block do
    dbi = Chef::Resource::ChefDataBagItem.new("delivery/#{delivery_server_version}", run_context)
    dbi.chef_server(chef_server_config)
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
  chef_server lazy { chef_server_config }
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

machine_file 'delivery-server-cert' do
  chef_server lazy { chef_server_config }
  path lazy { "/var/opt/delivery/nginx/ca/#{delivery_server_ip}.crt" }
  machine delivery_server_hostname
  local_path lazy { "#{Chef::Config[:trusted_certs_dir]}/#{delivery_server_ip}.crt" }
  action :download
end

# Create the default Delivery enterprise
machine_execute "Creating Enterprise" do
  chef_server lazy { chef_server_config }
  command lazy { delivery_enterprise_cmd }
  machine delivery_server_hostname
end

# Download the credentials form the Delivery server
machine_file "/tmp/#{node['delivery-cluster']['delivery']['enterprise']}.creds" do
  chef_server lazy { chef_server_config }
  machine delivery_server_hostname
  local_path "#{tmp_infra_dir}/#{node['delivery-cluster']['delivery']['enterprise']}.creds"
  action :download
end

#########################################################################
# Create Delivery builders
#########################################################################

# Create the Delivery builder role
chef_role 'delivery_builders' do
  chef_server lazy { chef_server_config }
  description "Base Role for the Delivery Build Nodes"
  run_list ["recipe[push-jobs]","recipe[delivery_builder]"]
end

# Provision our builders in parallel
machine_batch "#{node['delivery-cluster']['builders']['count']}-build-nodes" do
  1.upto(node['delivery-cluster']['builders']['count']) do |i|
    machine delivery_builder_hostname(i) do
      chef_server lazy { chef_server_config }
      role 'delivery_builders'
      add_machine_options(
        bootstrap_options: {image_id: node['delivery-cluster']['aws']['image_id']},
        convergence_options: {
          chef_config_text: "encrypted_data_bag_secret File.join(File.dirname(__FILE__), 'encrypted_data_bag_secret')",
          ssl_verify_mode: :verify_none
        }
      )
      add_machine_options bootstrap_options: { instance_type: node['delivery-cluster']['builders']['flavor']  } if node['delivery-cluster']['builders']['flavor']
      files lazy {{
        "/etc/chef/trusted_certs/#{chef_server_ip}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_ip}.crt",
        "/etc/chef/trusted_certs/#{delivery_server_ip}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{delivery_server_ip}.crt",
        '/etc/chef/encrypted_data_bag_secret' => "#{tmp_infra_dir}/encrypted_data_bag_secret"
      }}
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
