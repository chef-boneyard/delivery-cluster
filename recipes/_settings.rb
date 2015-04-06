#
# Cookbook Name:: delivery-cluster
# Recipe:: _settings
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

create_provisioning(DeliveryCluster::Provisioning.for_driver(node['delivery-cluster']['driver'], node))

with_driver provisioning.driver

with_machine_options(provisioning.machine_options)
