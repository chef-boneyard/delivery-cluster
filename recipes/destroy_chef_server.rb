#
# Cookbook Name:: delivery-cluster
# Recipe:: destroy_chef_server
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

# Starting to abstract the specific configurations by providers
include_recipe 'delivery-cluster::_settings'

# Setting the chef-zero process
with_chef_server Chef::Config.chef_server_url

# Destroy Chef Server
machine chef_server_hostname do
  action :destroy
end

# Delete Trusted Cert
file File.join(Chef::Config[:trusted_certs_dir], "#{chef_server_fqdn}.crt") do
  action :delete
end
