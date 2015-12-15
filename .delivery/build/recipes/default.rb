#
# Cookbook Name:: build
# Recipe:: default
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

# Gems for our tests
%w{watir-webdriver phantomjs artifactory}.each do |g|
  chef_gem g
end

# Package dependency in phantomjs for Linux systems
package 'libfontconfig1' unless platform_family?('windows')

# Make sure we can compile gems with make
include_recipe 'build-essential::default'
package 'libxml2-dev' unless platform_family?('windows')

include_recipe 'delivery-sugar-extras::default'
include_recipe 'delivery-matrix::default'
include_recipe 'delivery-truck::default'

# Temporal cache directory to store delivery-cluster-data
directory backup_dir do
  owner node['delivery_builder']['build_user']
  group node['delivery_builder']['build_user']
end

# Installing chef-provisioning drivers for testing purposes
%w(ssh vagrant aws).each do |driver|
  chef_gem "chef-provisioning-#{driver}" do
    action :install
  end
end
