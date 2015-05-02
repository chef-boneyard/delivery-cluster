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

# It's ugly but this must happen in the compile phase so we can switch out
# the Chef Server we are talking to for the remainder of the CCR.

# Provision the Chef Server with an empty runlist so we can extract
# it's primary ipaddress to use as the hostname in the initial
# `/etc/opscode/chef-server.rb` file
machine chef_server_hostname do
  provisioning.specific_machine_options('chef-server').each do |option|
    add_machine_options (option)
  end
  # Transfer any trusted certs from the current CCR
  Dir.glob("#{Chef::Config[:trusted_certs_dir]}/*.{crt,pem}").each do |cert_path|
    file cert_path, cert_path
  end
  action :converge
end

# Now that we've extracted the Chef Server's ipaddress we can fully
# converge and complete the install.
machine chef_server_hostname do
  if node['delivery-cluster']['chef-server']['existing']
    recipe "chef-server-12::delivery_setup"
  else
    recipe "chef-server-12"
  end
  attributes lazy { chef_server_attributes }
  converge true
  action :converge
end

directory Chef::Config[:trusted_certs_dir] do
  action :create
end

machine_file 'chef-server-cert' do
  path lazy { "/var/opt/opscode/nginx/ca/#{chef_server_ip}.crt" }
  machine chef_server_hostname
  local_path lazy { "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_ip}.crt" }
  action :download
end

directory cluster_data_dir do
  recursive true
  action :create
end

# Fetch our client and validator pems from the provisioned Chef Server
machine_file "/tmp/validator.pem" do
  machine chef_server_hostname
  local_path "#{cluster_data_dir}/validator.pem"
  action :download
end

machine_file "/tmp/delivery.pem" do
  machine chef_server_hostname
  mode "0644"                                     # This is not working.
  local_path "#{cluster_data_dir}/delivery.pem"
  action :download
end

# Workaround: Ensure that the `delivery.pem` has the right permissions.
# PR: https://github.com/chef/chef-provisioning/issues/174
file "#{cluster_data_dir}/delivery.pem" do
  mode '0644'
end

# generate a knife config file that points at the new Chef Server
render_knife_config

execute "upload delivery cookbooks" do
  command "knife cookbook upload --all --cookbook-path #{Chef::Config[:cookbook_path]} --force"
  environment(
    'KNIFE_HOME' => cluster_data_dir
  )
end
