#
# Cookbook Name:: build
# Recipe:: provision_extra_case
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
chef_gem "chef-rewind"
require 'chef/rewind'

cluster_name = "#{node['delivery']['change']['stage']}_#{node['delivery']['change']['pipeline']}"
path = node['delivery']['workspace']['repo']
delivery_version = ::DeliverySugarExtras::Helpers.get_delivery_versions(node)[1]

include_recipe "build::provision_clean_aws"

rewind "template[Create Environment Template]" do
  variables(
    :delivery_license => "#{cache}/delivery.license",
    :delivery_version => delivery_version,
    :cluster_name => cluster_name
  )
end
