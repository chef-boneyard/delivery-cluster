#
# Cookbook Name:: delivery-cluster
# Recipe:: _settings
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

with_driver provisioning.driver

with_machine_options(provisioning.machine_options)

# Link the actual "cluster_data_dir" to "delivery-cluster-data"
# so that ".chef/knife.rb" knows which one is our working cluster
link File.join(current_dir, '.chef', 'delivery-cluster-data') do
  to cluster_data_dir
end

# Verify Chef Software License
unless node['delivery-cluster']['accept_license']
  raise 'It is required to accept the Chef Software License Agreement ' \
        "(https://www.chef.io/online-master-agreement/).\nSee also: " \
        'https://github.com/chef-cookbooks/delivery-cluster#accept-license'
end
