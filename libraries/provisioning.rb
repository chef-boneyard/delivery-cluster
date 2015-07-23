#
# Cookbook Name:: delivery-cluster
# Library:: provisioning
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
module DeliveryCluster
  #
  # Module to create instances of Provisioning Drivers
  #
  module Provisioning
    # Returns an instance of a driver given a driver type string.
    #
    # @param driver [String] a driver type, to be constantized
    # @return [Provisioning::Base] a driver instance
    def self.for_driver(driver, node)
      str_const = driver.split('_').map(&:capitalize).join

      klass = const_get(str_const)
      klass.new(node)
    rescue => e
      raise "Could not load the '#{driver}' driver: #{e.message}"
    end
  end
end

Chef::Recipe.send(:include, DeliveryCluster::Provisioning)
Chef::Resource.send(:include, DeliveryCluster::Provisioning)
