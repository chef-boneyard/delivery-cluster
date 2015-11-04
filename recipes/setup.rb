#
# Cookbook Name:: delivery-cluster
# Recipe:: setup
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

# Starting to abstract the specific configurations by providers
#
# This is also useful when other cookbooks depend on "delivery-cluster"
# and they need to configure the same set of settings. e.g. (delivery-demo)
include_recipe 'delivery-cluster::_settings'

# Phase 1: Bootstrap a Chef Server instance with Chef-Zero
include_recipe 'delivery-cluster::setup_chef_server'

# Phase 2: Create a Supermarket Server if enabled (Cookbook Workflow)
unless node['delivery-cluster']['supermarket'].nil?
  include_recipe 'delivery-cluster::setup_supermarket'
end

# Phase 3: Create all the Delivery specific prerequisites
include_recipe 'delivery-cluster::setup_delivery'
