#
# Cookbook Name:: delivery-cluster
# Recipe:: delivery
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

chef_ingredient 'delivery' do
  version node['delivery-cluster']['delivery']['version']
  channel node['delivery-cluster']['delivery']['release-channel'].to_sym
  notifies :run, 'execute[reconfigure delivery]'
  action :upgrade
end

directory '/etc/delivery' do
  recursive true
end

template '/etc/delivery/delivery.rb' do
  variables(
    default_search: '((recipes:delivery_build OR ' \
                    'recipes:delivery_build\\\\\\\\:\\\\\\\\:default) ' \
                    "AND chef_environment:#{node.chef_environment})"
  )
  notifies :run, 'execute[reconfigure delivery]'
end

unless ::File.exist?('/etc/delivery/delivery.pem')
  # We are assuming that there is already a "encrypted_data_bag_secret"
  # configured on "solo.rb" file. This is not any secret key. This MUST
  # be the key generated from the "chef-server-12" cookbook.
  pem = Chef::EncryptedDataBagItem.load('delivery', 'delivery_pem', Chef::Config.encrypted_data_bag_secret)

  file '/etc/delivery/delivery.pem' do
    content pem['content']
    mode 0644
    notifies :run, 'execute[reconfigure delivery]'
  end
end

execute 'reconfigure delivery' do
  command '/opt/delivery/bin/delivery-ctl reconfigure'
  action :nothing
end
