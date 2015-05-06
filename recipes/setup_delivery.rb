#
# Cookbook Name:: delivery-cluster
# Recipe:: setup_delivery
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'delivery-cluster::_settings'

# create an encrypted data bag secret
file "#{cluster_data_dir}/encrypted_data_bag_secret" do
  mode '0644'
  content encrypted_data_bag_secret
  sensitive true
  action :create
end

# create required builder keys
execute 'builder ssh key' do
  command "ssh-keygen -t rsa -N '' -b 2048 -f #{cluster_data_dir}/builder_key"
  not_if { File.exist?("#{cluster_data_dir}/builder_key") }
end

# create the data bag (and item) to store our builder keys
chef_data_bag 'keys' do
  chef_server lazy { chef_server_config }
  action :create
end

chef_data_bag_item 'keys/delivery_builder_keys' do
  chef_server lazy { chef_server_config }
  raw_data lazy {
    {
      builder_key:  builder_private_key,
      delivery_pem: File.read("#{cluster_data_dir}/delivery.pem")
    }
  }
  secret_path "#{cluster_data_dir}/encrypted_data_bag_secret"
  encryption_version 1
  encrypt true
  action :create
end

# Phase 3: Bootstrap the rest of our infrastructure with the new Chef Server
#
# Provision the Delivery server with an empty runlist so we can extract
# it's primary ipaddress to use as the hostname in the initial
# "/etc/opscode/delivery.rb" file
machine delivery_server_hostname do
  chef_server lazy { chef_server_config }
  provisioning.specific_machine_options('delivery').each do |option|
    add_machine_options option
  end
  files lazy {
    {
      "/etc/chef/trusted_certs/#{chef_server_ip}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_ip}.crt"
    }
  }
  action :converge
end

# Right now, we should enforce license checks only for latest or post-0.3.0
# versions of Delivery. Once all our customers are on post-0.3.0 versions of
# Delivery we could remove this conditional.
if node['delivery-cluster']['delivery']['version'] == 'latest' ||
   Gem::Version.new(node['delivery-cluster']['delivery']['version']) > Gem::Version.new('0.3.0')
  # Fail early if license files cannot be found
  validate_license_file

  # Upload the license information to the Delivery Server
  machine_execute 'Create "/var/opt/delivery/license" directory on Delivery Server' do
    chef_server lazy { chef_server_config }
    command 'mkdir -p /var/opt/delivery/license'
    machine delivery_server_hostname
  end

  machine_file '/var/opt/delivery/license/delivery.license' do
    chef_server lazy { chef_server_config }
    machine delivery_server_hostname
    local_path node['delivery-cluster']['delivery']['license_file']
    action :upload
  end
end

# Now that we've extracted the Delivery Server's ipaddress we can fully
# converge and complete the install.
machine delivery_server_hostname do
  chef_server lazy { chef_server_config }
  recipe 'delivery-cluster::delivery'
  files(
    '/etc/delivery/delivery.pem' => "#{cluster_data_dir}/delivery.pem",
    '/etc/delivery/builder_key' => "#{cluster_data_dir}/builder_key",
    '/etc/delivery/builder_key.pub' => "#{cluster_data_dir}/builder_key.pub"
  )
  attributes lazy { delivery_server_attributes }
  converge true
  action :converge
end

# Set right permissions to delivery files
machine_execute "Chown '/etc/delivery' to 'delivery' user" do
  chef_server lazy { chef_server_config }
  command 'chown -R delivery /etc/delivery'
  machine delivery_server_hostname
end

machine_file 'delivery-server-cert' do
  chef_server lazy { chef_server_config }
  path lazy { "/var/opt/delivery/nginx/ca/#{delivery_server_ip}.crt" }
  machine delivery_server_hostname
  local_path lazy { "#{Chef::Config[:trusted_certs_dir]}/#{delivery_server_ip}.crt" }
  action :download
end

# Create the default Delivery enterprise
machine_execute 'Creating Enterprise' do
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
  description 'Base Role for the Delivery Build Nodes'
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
      provisioning.specific_machine_options('builders', i).each do |option|
        add_machine_options option
      end
      files lazy {
        {
          "/etc/chef/trusted_certs/#{chef_server_ip}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_ip}.crt",
          "/etc/chef/trusted_certs/#{delivery_server_ip}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{delivery_server_ip}.crt",
          '/etc/chef/encrypted_data_bag_secret' => "#{cluster_data_dir}/encrypted_data_bag_secret"
        }
      }
      attributes lazy { builders_attributes }
      converge true
      action :converge
    end
  end
end

# Set right permissions to dbuild cert files on build-nodes
1.upto(node['delivery-cluster']['builders']['count']) do |i|
  machine_execute "Chown '/etc/chef/trusted_certs' to 'dbuild' user on [#{delivery_builder_hostname(i)}]" do
    chef_server lazy { chef_server_config }
    command 'chown -R dbuild /etc/chef/trusted_certs'
    machine delivery_builder_hostname(i)
  end
end

# Print the generated Delivery server credentials
ruby_block 'print-delivery-credentials' do
  block do
    puts File.read("#{cluster_data_dir}/#{node['delivery-cluster']['delivery']['enterprise']}.creds")
  end
end
