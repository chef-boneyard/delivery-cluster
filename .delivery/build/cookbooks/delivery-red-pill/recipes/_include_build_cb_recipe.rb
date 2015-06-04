#
# Cookbook Name:: delivery-red-pill
# Recipe:: _include_build_cb_recipe
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
build_cb_name = node['delivery']['config']['build_cookbook']['name'] || node['delivery']['config']['build_cookbook']
phase = node['delivery']['change']['phase']
pipeline = node['delivery']['change']['pipeline']
include_recipe "#{build_cb_name}::#{phase}_#{pipeline}"
