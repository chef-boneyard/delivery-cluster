#
# Cookbook Name:: delivery-cluster
# Recipe:: setup_supermarket
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

# There are two ways to provision the Supermarket Server
#
# 1) Provisioning the entire "delivery-cluster::setup" or
# 2) Just the Chef Server "delivery-cluster::setup_chef_server"
#
# After that you are good to provision Supermarket running:
# => # bundle exec chef-client -z -o delivery-cluster::setup_supermarket -E test

machine supermarket_server_hostname do
  chef_server lazy { chef_server_config }
  provisioning.specific_machine_options('supermarket').each do |option|
    add_machine_options option
  end
  files lazy {
    {
      "/etc/chef/trusted_certs/#{chef_server_fqdn}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_fqdn}.crt"
    }
  }
  action :converge
end

# Activate Supermarket
activate_supermarket

# Configuring Supermarket on the Chef Server
machine chef_server_hostname do
  recipe 'chef-server-12::supermarket'
  attributes lazy { chef_server_attributes }
  converge true
  action :converge
end

machine_file '/etc/opscode/oc-id-applications/supermarket.json' do
  machine chef_server_hostname
  local_path "#{cluster_data_dir}/supermarket.json"
  action :download
end

# Installing Sypermarket
machine supermarket_server_hostname do
  chef_server lazy { chef_server_config }
  recipe 'supermarket-omnibus-cookbook'
  attributes lazy {
    {
      'supermarket_omnibus' => {
        'chef_server_url' => "https://#{chef_server_fqdn}",
        'chef_oauth2_app_id' => get_supermarket_attribute('uid'),
        'chef_oauth2_secret' => get_supermarket_attribute('secret'),
        'chef_oauth2_verify_ssl' => false
      }
    }
  }
  converge true
  action :converge
end

machine_file 'supermarket-server-cert' do
  chef_server lazy { chef_server_config }
  path lazy { "/var/opt/supermarket/ssl/ca/#{supermarket_server_fqdn}.crt" }
  machine supermarket_server_hostname
  local_path lazy { "#{Chef::Config[:trusted_certs_dir]}/#{supermarket_server_fqdn}.crt" }
  action :download
end

# Add Supermarket Server to the knife.rb config file
render_knife_config
