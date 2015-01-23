#
# Cookbook Name:: delivery-cluster
# Recipe:: destory_all
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe "delivery-cluster::destroy_builders"
include_recipe "delivery-cluster::destroy_delivery"
include_recipe "delivery-cluster::destroy_chef_server"
include_recipe "delivery-cluster::destroy_keys"
