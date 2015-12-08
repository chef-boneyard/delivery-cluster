#
# Cookbook Name:: delivery-matrix
# Recipe:: _include_build_cb_recipe
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

build_cb_name = node['delivery']['config']['build_cookbook']['name'] || node['delivery']['config']['build_cookbook']
phase = node['delivery']['change']['phase']
pipeline = node['delivery']['change']['pipeline']
include_recipe "#{build_cb_name}::#{phase}_#{pipeline}"
