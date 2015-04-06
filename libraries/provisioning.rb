#
# Cookbook Name:: delivery-cluster
# Library:: provisioning
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#
require "thor/util"

module DeliveryCluster
  module Provisioning

    # Returns an instance of a driver given a driver type string.
    #
    # @param driver [String] a driver type, to be constantized
    # @return [Provisioning::Base] a driver instance
    def self.for_driver(driver, node)
      str_const = Thor::Util.camel_case(driver)
      klass = const_get(str_const)
      klass.new(node)
    rescue
      raise "Could not load the '#{driver}' driver from the load path."
    end
  end
end

Chef::Recipe.send(:include, DeliveryCluster::Provisioning)
Chef::Resource.send(:include, DeliveryCluster::Provisioning)
