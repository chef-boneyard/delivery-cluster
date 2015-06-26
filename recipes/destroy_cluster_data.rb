#
# Cookbook Name:: delivery-cluster
# Recipe:: destroy_cluster_data
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

# Delete Link "delivery-cluster-data"
link File.join(current_dir, '.chef', 'delivery-cluster-data') do
  action :delete
  only_if { cluster_data_dir_link? }
end

# Delete "cluster_data_dir" directory
directory cluster_data_dir do
  recursive true
  action :delete
end
