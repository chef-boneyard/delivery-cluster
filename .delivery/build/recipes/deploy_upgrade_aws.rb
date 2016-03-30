#
# Cookbook Name:: build
# Recipe:: deploy_upgrade_aws
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

chef_gem "chef-rewind"
require 'chef/rewind'

delivery_secrets = get_project_secrets

root = node['delivery']['workspace']['root']

ruby_block 'Restore Provisioning Bits' do
  block do
    restore_cluster_data(root, node, delivery_secrets)
  end
end

include_recipe 'build::provision_clean_aws'

unwind 'ruby_block[Destroy old Delivery Cluster]'

rewind 'ruby_block[Create a new Delivery Cluster]' do
  name 'Upgrade Delivery Cluster'
end
