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

with_driver provisioning.driver

with_machine_options(provisioning.machine_options)

# Link the actual `cluster_data_dir` to `delivery-cluster-data`
# so that `.chef/knife.rb` knows which one is our working cluster
link File.join(current_dir, '.chef', "delivery-cluster-data") do
  to cluster_data_dir
end
