#
# Cookbook Name:: delivery-cluster
# Recipe:: setup
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

# Starting to abstract the specific configurations by providers
#
# This is also useful when other cookbooks depend on `delivery-cluster`
# and they need to configure the same set of settings. e.g. (delivery-demo)
include_recipe 'delivery-cluster::_aws_settings'

# Phase 1: Bootstrap a Chef Server instance with Chef-Zero
include_recipe 'delivery-cluster::setup_chef_server'

# Phase 2: Create all the Delivery specific prerequisites
include_recipe 'delivery-cluster::setup_delivery'
