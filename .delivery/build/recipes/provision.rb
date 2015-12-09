#
# Cookbook Name:: build
# Recipe:: provision
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

# By including this recipe we trigger a matrix of acceptance envs specified
# in the node attribute node['delivery-matrix']['acceptance']['matrix']
if node['delivery']['change']['stage'] == 'acceptance'
  include_recipe 'delivery-matrix::provision'
end
