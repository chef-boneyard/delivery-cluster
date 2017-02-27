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

chef_data_bag_item 'delivery_builder_keys' do
  # Workaround until we release chefdk 0.11.1 with
  # Cheffish fix: https://github.com/chef/cheffish/pull/99
  data_bag 'keys'
  chef_server lazy { chef_server_config }
  raw_data lazy {
    {
      builder_key:  builder_private_key,
      delivery_pem: File.read("#{cluster_data_dir}/delivery.pem"),
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
      "/etc/chef/trusted_certs/#{chef_server_fqdn}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_fqdn}.crt",
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
    mode '0644'
  end
end

# Now that we've extracted the Delivery Server's ipaddress we can fully
# converge and complete the install.
machine delivery_server_hostname do
  chef_server lazy { chef_server_config }
  provisioning.specific_machine_options('delivery').each do |option|
    add_machine_options option
  end
  common_cluster_recipes.each { |r| recipe r }
  recipe 'delivery-cluster::delivery'
  node['delivery-cluster']['delivery']['recipes'].each { |r| recipe r }
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
%w( delivery.pem builder_key builder_key.pub ).each do |file|
  machine_execute "Chown '/etc/delivery/#{file}' to 'delivery' user" do
    chef_server lazy { chef_server_config }
    command "chown delivery /etc/delivery/#{file}"
    machine delivery_server_hostname
  end
end

machine_file 'delivery-server-cert' do
  chef_server lazy { chef_server_config }
  path lazy { "/var/opt/delivery/nginx/ca/#{delivery_server_fqdn}.crt" }
  machine delivery_server_hostname
  local_path lazy { "#{Chef::Config[:trusted_certs_dir]}/#{delivery_server_fqdn}.crt" }
  action :download
end

machine_file 'delivery-server-cert-key' do
  chef_server lazy { chef_server_config }
  path lazy { "/var/opt/delivery/nginx/ca/#{delivery_server_fqdn}.key" }
  machine delivery_server_hostname
  local_path lazy { "#{Chef::Config[:trusted_certs_dir]}/#{delivery_server_fqdn}.key" }
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

# Print the generated Delivery server credentials
ruby_block 'print-delivery-credentials' do
  block do
    puts File.read("#{cluster_data_dir}/#{node['delivery-cluster']['delivery']['enterprise']}.creds")
  end
end

# Activate Insights
ruby_block 'Activate Insights' do
  block { activate_insights }
  only_if { node['delivery-cluster']['delivery']['insights']['enable'] }
end

machine chef_server_hostname do
  provisioning.specific_machine_options('chef-server').each do |option|
    add_machine_options(option)
  end
  attributes lazy { chef_server_attributes }
  only_if { node['delivery-cluster']['delivery']['insights']['enable'] }
  not_if { node['delivery-cluster']['chef-server']['existing'] }
  action :converge
end

# Print Insights Config to add to Existing Chef Server
ruby_block 'Print Insights Config' do
  block { pretty_insights_config }
  only_if { node['delivery-cluster']['delivery']['insights']['enable'] }
  only_if { node['delivery-cluster']['chef-server']['existing'] }
end
