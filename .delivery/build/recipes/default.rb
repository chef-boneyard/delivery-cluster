#
# Cookbook Name:: build
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'delivery-truck::default'

# copy the nodes and clients dir outside of workspace
directory "/var/opt/delivery/workspace/delivery-cluster-aws-cache" do
  owner node['delivery_builder']['build_user']
  group node['delivery_builder']['build_user']
end