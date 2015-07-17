#
# Cookbook Name:: chef-server-cluster
# Recipes:: analytics
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

directory '/etc/opscode' do
  recursive true
end

directory '/etc/opscode-analytics' do
  recursive true
end

file '/etc/opscode-analytics/opscode-analytics.rb' do
  content <<-EOF
topology 'standalone'
analytics_fqdn '#{node['delivery-cluster']['analytics']['fqdn']}'
features['integration'] = #{node['delivery-cluster']['analytics']['features']}
  EOF
  notifies :reconfigure, 'chef_server_ingredient[opscode-analytics]'
end

chef_ingredient 'analytics' do
  notifies :reconfigure, 'chef_ingredient[analytics]'
end
