#
# Cookbook Name:: delivery-cluster
# Recipe:: setup_delivery_server
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

# Phase 1: Create key for delivery user to talk to each other
execute 'delivery primary ssh key' do
  command "ssh-keygen -t rsa -N '' -b 2048 -f #{cluster_data_dir}/#{delivery_primary_key_name}"
  not_if { File.exist?("#{cluster_data_dir}/#{delivery_primary_key_name}") }
end

execute 'delivery standby ssh key' do
  command "ssh-keygen -t rsa -N '' -b 2048 -f #{cluster_data_dir}/#{delivery_standby_key_name}"
  not_if { File.exist?("#{cluster_data_dir}/#{delivery_standby_key_name}") }
end

# create the data bag (and item) to store our builder keys
chef_data_bag 'keys' do
  chef_server lazy { chef_server_config }
  action :create
end

chef_data_bag_item 'delivery_primary_keys' do
  # Workaround until we release chefdk 0.11.1 with
  # Cheffish fix: https://github.com/chef/cheffish/pull/99
  data_bag 'keys'
  chef_server lazy { chef_server_config }
  raw_data lazy {
    {
      private_key: delivery_primary_private_key,
      public_key: delivery_primary_public_key,
    }
  }
  secret_path "#{cluster_data_dir}/encrypted_data_bag_secret"
  encryption_version 1
  encrypt true
  action :create
end

chef_data_bag_item 'delivery_standby_keys' do
  # Workaround until we release chefdk 0.11.1 with
  # Cheffish fix: https://github.com/chef/cheffish/pull/99
  data_bag 'keys'
  chef_server lazy { chef_server_config }
  raw_data lazy {
    {
      private_key: delivery_standby_private_key,
      public_key: delivery_standby_public_key,
    }
  }
  secret_path "#{cluster_data_dir}/encrypted_data_bag_secret"
  encryption_version 1
  encrypt true
  action :create
end

# Phase 2: Create Standby so it is on chef server for queries
machine delivery_server_dr_hostname do
  chef_server lazy { chef_server_config }
  provisioning.specific_machine_options('delivery', 'disaster_recovery').each do |option|
    add_machine_options option
  end
  attributes lazy { delivery_server_attributes }
  files lazy {
    {
      "/etc/chef/trusted_certs/#{chef_server_fqdn}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_fqdn}.crt",
      '/etc/chef/encrypted_data_bag_secret' => "#{DeliveryCluster::Helpers.cluster_data_dir(node)}/encrypted_data_bag_secret",
    }
  }
  action :converge
end

# Phase 3: Setup the primary to do replication
machine delivery_server_hostname do
  chef_server lazy { chef_server_config }
  provisioning.specific_machine_options('delivery').each do |option|
    add_machine_options option
  end
  common_cluster_recipes.each { |r| recipe r }
  recipe 'delivery-cluster::delivery_dr'
  attributes lazy { delivery_server_attributes(:primary) }
  files lazy {
    {
      "/etc/chef/trusted_certs/#{chef_server_fqdn}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_fqdn}.crt",
      '/etc/chef/encrypted_data_bag_secret' => "#{DeliveryCluster::Helpers.cluster_data_dir(node)}/encrypted_data_bag_secret",
    }
  }
  action :converge
end

# Phase 4: Setup the Standby to sync from primary

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
    machine delivery_server_dr_hostname
  end

  machine_file '/var/opt/delivery/license/delivery.license' do
    chef_server lazy { chef_server_config }
    machine delivery_server_dr_hostname
    local_path node['delivery-cluster']['delivery']['license_file']
    action :upload
    mode '0644'
  end
end

# Now that we've extracted the Delivery Server's ipaddress we can fully
# converge and complete the install.
machine delivery_server_dr_hostname do
  chef_server lazy { chef_server_config }
  provisioning.specific_machine_options('delivery', 'disaster_recovery').each do |option|
    add_machine_options option
  end
  common_cluster_recipes.each { |r| recipe r }
  recipe 'delivery-cluster::delivery'
  recipe 'delivery-cluster::delivery_dr'
  node['delivery-cluster']['delivery']['recipes'].each { |r| recipe r }
  files(
    '/etc/delivery/delivery.pem' => "#{cluster_data_dir}/delivery.pem",
    '/etc/delivery/builder_key' => "#{cluster_data_dir}/builder_key",
    '/etc/delivery/builder_key.pub' => "#{cluster_data_dir}/builder_key.pub"
  )
  attributes lazy { delivery_server_attributes(:standby) }
  converge true
  action :converge
end

# Set right permissions to delivery files
%w( delivery.pem builder_key builder_key.pub ).each do |file|
  machine_execute "Chown '/etc/delivery/#{file}' to 'delivery' user" do
    chef_server lazy { chef_server_config }
    command "chown delivery /etc/delivery/#{file}"
    machine delivery_server_dr_hostname
  end
end

machine_file 'delivery-server-cert' do
  chef_server lazy { chef_server_config }
  path lazy { "/var/opt/delivery/nginx/ca/#{delivery_server_fqdn}.crt" }
  machine delivery_server_dr_hostname
  local_path lazy { "#{Chef::Config[:trusted_certs_dir]}/#{delivery_server_fqdn}.crt" }
  action :upload
end

machine_file 'delivery-server-cert-key' do
  chef_server lazy { chef_server_config }
  path lazy { "/var/opt/delivery/nginx/ca/#{delivery_server_fqdn}.key" }
  machine delivery_server_dr_hostname
  local_path lazy { "#{Chef::Config[:trusted_certs_dir]}/#{delivery_server_fqdn}.key" }
  action :upload
end
