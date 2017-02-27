#
# Cookbook Name:: delivery-cluster
# Recipe:: setup_delivery_builders
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

# Create the Delivery builder role
chef_role 'delivery_builders' do
  chef_server lazy { chef_server_config }
  description 'Base Role for the Delivery Build Nodes'
  run_list builder_run_list
end

# Provision our builders in parallel
machine_batch "#{node['delivery-cluster']['builders']['count']}-build-nodes" do
  1.upto(node['delivery-cluster']['builders']['count'].to_i) do |i|
    machine delivery_builder_hostname(i) do
      chef_server lazy { chef_server_config }
      common_cluster_recipes.each { |r| recipe r }
      role 'delivery_builders'
      add_machine_options(
        convergence_options: {
          chef_config_text: "encrypted_data_bag_secret File.join(File.dirname(__FILE__), 'encrypted_data_bag_secret')",
          ssl_verify_mode: :verify_none,
        }
      )
      provisioning.specific_machine_options('builders', i).each do |option|
        add_machine_options option
      end
      files lazy { builders_files }
      attributes lazy { builders_attributes }
      converge true
      action :converge
    end
  end
end
