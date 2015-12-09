#
# Cookbook Name:: build
# Recipe:: functional
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

# ## By including this recipe we trigger a matrix of acceptance envs specified
# ## in the node attribute node['delivery-matrix']['acceptance']['matrix']

if node['delivery']['change']['pipeline'] == 'master'
  if node['delivery']['change']['stage'] == 'acceptance'
    include_recipe "delivery-matrix::functional"
  elsif node['delivery']['change']['stage'] == 'delivered'
    # This was lifted from delivery-truck publish
    secrets = get_project_secrets
    github_repo = node['delivery']['config']['delivery-truck']['publish']['github']

    delivery_github github_repo do
      deploy_key secrets['github']
      branch node['delivery']['change']['pipeline']
      remote_url "git@github.com:#{github_repo}.git"
      repo_path node['delivery']['workspace']['repo']
      cache_path node['delivery']['workspace']['cache']
      action :push
    end
  end
end
