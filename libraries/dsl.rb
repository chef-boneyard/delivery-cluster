#
# Cookbook Name:: delivery-cluster
# Library:: dsl
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
#

require_relative 'helpers'
require_relative 'helpers_component'
require_relative 'helpers_chef_server'
require_relative 'helpers_delivery'
require_relative 'helpers_builders'
require_relative 'helpers_supermarket'
require_relative 'helpers_analytics'
require_relative 'helpers_splunk'

Chef::Recipe.send(:include, DeliveryCluster::DSL)
Chef::Resource.send(:include, DeliveryCluster::DSL)
Chef::Provider.send(:include, DeliveryCluster::DSL)
