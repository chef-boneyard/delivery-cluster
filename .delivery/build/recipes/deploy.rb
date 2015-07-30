#
# Cookbook Name:: build
# Recipe:: deploy
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
chef_gem "chef-rewind"
require 'chef/rewind'

if node['delivery']['change']['pipeline'] == 'upgrade_aws' &&
  node['delivery']['change']['stage'] == 'acceptance'
  cluster_name     = "#{node['delivery']['change']['stage']}_#{node['delivery']['change']['pipeline']}"
  path             = node['delivery']['workspace']['repo']
  cache            = node['delivery']['workspace']['cache']

  ruby_block 'Restore Provisioning Bits' do
    block do
      restore_cluster_data(path)
    end
  end

  include_recipe "build::provision_clean_aws"

  unwind "execute[Destroy the old Delivery Cluster]"

  rewind "execute[Create a new Delivery Cluster]" do
    name "Upgrade Delivery Cluster"
  end
end
