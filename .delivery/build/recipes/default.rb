#
# Cookbook Name:: build
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'delivery-sugar-extras::default'
include_recipe 'delivery-red-pill::default'
include_recipe 'delivery-truck::default'

%w{watir-webdriver phantomjs}.each do |g|
  chef_gem g do
    compile_time true
  end
end

# Temporal cache directory to store delivery-cluster-data
directory "/var/opt/delivery/workspace/delivery-cluster-aws-cache" do
  owner node['delivery_builder']['build_user']
  group node['delivery_builder']['build_user']
end
