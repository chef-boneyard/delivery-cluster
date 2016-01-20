#
# Cookbook Name:: delivery-cluster
# Recipe:: setup_chef_server
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

# This must happen in the compile phase so we can switch out
# the Chef Server we are talking to for the remainder of the CCR.

# Provision the Chef Server with an empty runlist so we can extract
# it's primary ipaddress to use as the hostname in the initial
# "/etc/opscode/chef-server.rb" file
machine chef_server_hostname do
  provisioning.specific_machine_options('chef-server').each do |option|
    add_machine_options(option)
  end
  # Transfer any trusted certs
  Dir.glob("#{Chef::Config[:trusted_certs_dir]}/*").each do |cert_path|
    file ::File.join('/etc/chef/trusted_certs', ::File.basename(cert_path)), cert_path
  end
  action :converge
end

directory cluster_data_dir do
  recursive true
  action :create
end

# Lay down the password of the delivery user in the Chef Server
file "#{cluster_data_dir}/chef_server_delivery_password" do
  mode '0644'
  content chef_server_delivery_password
  sensitive true
  action :create
end

# Now that we've extracted the Chef Server's ipaddress we can fully
# converge and complete the install.
machine chef_server_hostname do
  provisioning.specific_machine_options('chef-server').each do |option|
    add_machine_options(option)
  end
  common_cluster_recipes.each { |r| recipe r }
  if node['delivery-cluster']['chef-server']['existing']
    recipe 'chef-server-12::delivery_setup'
  else
    recipe 'chef-server-12'
  end
  node['delivery-cluster']['chef-server']['recipes'].each { |r| recipe r }
  attributes lazy { chef_server_attributes }
  converge true
  action :converge
end

directory Chef::Config[:trusted_certs_dir] do
  action :create
end

machine_file 'chef-server-cert' do
  path lazy { "/var/opt/opscode/nginx/ca/#{chef_server_fqdn}.crt" }
  machine chef_server_hostname
  local_path lazy { "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_fqdn}.crt" }
  action :download
end

# Fetch our client and validator pems from the provisioned Chef Server
machine_file '/tmp/validator.pem' do
  machine chef_server_hostname
  local_path "#{cluster_data_dir}/validator.pem"
  action :download
end

machine_file '/tmp/delivery.pem' do
  machine chef_server_hostname
  mode '0644' # This is not working.
  local_path "#{cluster_data_dir}/delivery.pem"
  action :download
end

# Workaround: Ensure that the "delivery.pem" has the right permissions.
# PR: https://github.com/chef/chef-provisioning/issues/174
file "#{cluster_data_dir}/delivery.pem" do
  mode '0644'
end

# Generate a knife config file that points at the new Chef Server
template File.join(cluster_data_dir, 'knife.rb') do
  variables lazy { knife_variables }
end

# Upload all the cookbook dependencies we need for Delivery
ruby_block 'upload delivery cookbooks' do
  block do
    require 'chef/knife/cookbook_upload'
    Chef::Config.from_file(File.join(cluster_data_dir, 'knife.rb'))
    Chef::Knife::CookbookUpload.load_deps
    knife = Chef::Knife::CookbookUpload.new
    knife.config[:cookbook_path]  = Chef::Config[:cookbook_path]
    knife.config[:all]            = true
    knife.config[:force]          = true
    knife.run
  end
end
