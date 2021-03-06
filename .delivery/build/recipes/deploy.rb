#
# Cookbook Name:: build
# Recipe:: deploy
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

if node['delivery']['change']['stage'] == 'acceptance'
  # In the deploy check to see if we are in an upgrade scenario and include
  # upgrade deploy recipes
  case node['delivery']['change']['pipeline']
  when 'upgrade_aws','upgrade_to_dr_aws'
    include_recipe "build::deploy_#{node['delivery']['change']['pipeline']}"
  end
end
