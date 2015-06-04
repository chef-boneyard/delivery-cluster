#
# Cookbook Name:: delivery-red-pill
# Recipe:: deploy
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
include_recipe 'delivery-truck::deploy'

if node['delivery']['change']['pipeline'] != 'master'
  include_recipe "delivery-red-pill::_include_build_cb_recipe"
end
