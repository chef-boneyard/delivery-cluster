#
# Cookbook Name:: delivery-cluster
# Recipe:: supermarket
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

hostsfile_entry node['ipaddress'] do
  hostname node.hostname
  not_if "grep #{node.hostname} /etc/hosts"
end

ingredient_config 'supermarket' do
  config JSON.pretty_generate(node['supermarket-config'])
  action :add
end

chef_ingredient 'supermarket' do
  action [:install, :reconfigure]
end
