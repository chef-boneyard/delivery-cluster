#
# Cookbook Name:: delivery-cluster
# Library:: pkg_repo_management
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
#
# PURPOSE: This recipe will do the management of the package repositories
# in a cross-platform manner.

case node['platform_family']
when 'debian'
  # Force the update at compile time
  node.set['apt']['compile_time_update'] = true
  include_recipe 'apt'
when 'rhel'
  include_recipe 'yum'
  # By default yum should clean the cache but we are going to force it
  # to ensure we will get the latest packages from our repositories.
  execute 'yum clean all' do
    action :nothing
  end.run_action(:run)
else
  log 'delivery-cluster-pkg-repo-update-not-handled' do
    message <<-EOF
      delivery-cluster mediated package repository updating is not yet handled
      for platform family #{node['platform_family']}. If this is an error, please
      update the `delivery-cluster::pkg_repo_management` recipe as appropriate
    EOF
  end
end
