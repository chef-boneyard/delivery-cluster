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

  execute "Restore Provisioning Bits" do
    cwd path
    command <<-EOF
      mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/clients clients
      mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/nodes nodes
      mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/trusted_certs .chef/.
      mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/delivery-cluster-data-* .chef/.
    EOF
    environment ({
      'AWS_CONFIG_FILE' => "#{cache}/.aws/config"
    })
    only_if do ::File.exists?('var/opt/delivery/workspace/delivery-cluster-aws-cache/nodes') end
  end

  include_recipe "build::provision_clean_aws"

  unwind "execute[Destroy the old Delivery Cluster]"
end
