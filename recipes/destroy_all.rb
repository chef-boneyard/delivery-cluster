#
# Cookbook Name:: delivery-cluster
# Recipe:: destory_all
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

# If we want to destroy everything. Let's do it! But in order.
# First: The servers that are registered to our chef-server
# => Build Nodes
include_recipe "delivery-cluster::destroy_builders"

# => Analytics Server
include_recipe "delivery-cluster::destroy_analytics"

# => Splunk Server
include_recipe "delivery-cluster::destroy_splunk"

# => Delivery Server
include_recipe "delivery-cluster::destroy_delivery"

# Then: We will destroy the chef-server that its being manage locally
include_recipe "delivery-cluster::destroy_chef_server"

# Finally: All the keys & creds used on the currect delivery-cluster
include_recipe "delivery-cluster::destroy_keys"
