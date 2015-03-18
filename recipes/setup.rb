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

# Starting to abstract the specific configurations by providers
#
# This is also useful when other cookbooks depend on `delivery-cluster`
# and they need to configure the same set of settings. e.g. (delivery-demo)
include_recipe 'delivery-cluster::_aws_settings'

# Phase 1: Bootstrap a Chef Server instance with Chef-Zero
include_recipe 'delivery-cluster::setup_chef_server'

# Phase 2: Create all the Delivery specific prerequisites

# create an encrypted data bag secret
file "#{cluster_data_dir}/encrypted_data_bag_secret" do
  mode    '0644'
  content encrypted_data_bag_secret
  sensitive true
  action :create
end

# create required builder keys
execute 'builder ssh key' do
  command "ssh-keygen -t rsa -N '' -b 2048 -f #{cluster_data_dir}/builder_key"
  not_if { File.exists?("#{cluster_data_dir}/builder_key") }
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
    delivery_pem: File.read("#{cluster_data_dir}/delivery.pem")
  }}
  secret_path "#{cluster_data_dir}/encrypted_data_bag_secret"
  encryption_version 1
  encrypt true
  action :create
end

# Phase 3: Bootstrap the rest of our infrastructure with the new Chef Server
#
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
  recipe "delivery-server"
  files(
    '/etc/delivery/delivery.pem' => "#{cluster_data_dir}/delivery.pem",
    '/etc/delivery/builder_key' => "#{cluster_data_dir}/builder_key",
    '/etc/delivery/builder_key.pub' => "#{cluster_data_dir}/builder_key.pub"
  )
  attributes lazy { delivery_server_attributes }
  converge true
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
  local_path "#{cluster_data_dir}/#{node['delivery-cluster']['delivery']['enterprise']}.creds"
  action :download
end

#########################################################################
# Create Delivery builders
#########################################################################

# Create the Delivery builder role
chef_role 'delivery_builders' do
  chef_server lazy { chef_server_config }
  description "Base Role for the Delivery Build Nodes"
  run_list builder_run_list
end

# Provision our builders in parallel
machine_batch "#{node['delivery-cluster']['builders']['count']}-build-nodes" do
  1.upto(node['delivery-cluster']['builders']['count']) do |i|
    machine delivery_builder_hostname(i) do
      chef_server lazy { chef_server_config }
      role 'delivery_builders'
      add_machine_options(
        convergence_options: {
          chef_config_text: "encrypted_data_bag_secret File.join(File.dirname(__FILE__), 'encrypted_data_bag_secret')",
          ssl_verify_mode: :verify_none
        }
      )
      add_machine_options bootstrap_options: { instance_type: node['delivery-cluster']['builders']['flavor']  } if node['delivery-cluster']['builders']['flavor']
      files lazy {{
        "/etc/chef/trusted_certs/#{chef_server_ip}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_ip}.crt",
        "/etc/chef/trusted_certs/#{delivery_server_ip}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{delivery_server_ip}.crt",
        '/etc/chef/encrypted_data_bag_secret' => "#{cluster_data_dir}/encrypted_data_bag_secret"
      }}
      converge true
      action :converge
    end
  end
end

# Print the generated Delivery server credentials
ruby_block "print-delivery-credentials" do
  block do
    puts File.read("#{cluster_data_dir}/#{node['delivery-cluster']['delivery']['enterprise']}.creds")
  end
end
