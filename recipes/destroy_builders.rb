#
# Cookbook Name:: delivery-cluster
# Recipe:: destroy_builders
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

require 'chef/provisioning/aws_driver'

with_driver 'aws'

# Only if we have the credentials to destroy it
if File.exist?("#{tmp_infra_dir}/delivery.pem")
  begin
    # Setting the new Chef Server we just created
    with_chef_server chef_server_url,
      client_name: 'delivery',
      signing_key_filename: "#{tmp_infra_dir}/delivery.pem"

    # Destroy Build Nodes
    machine_batch 'Destroying Build Nodes' do
      1.upto(node['delivery-cluster']['builders']['count']) do |i|
        machine delivery_builder_hostname(i)
      end
      action :destroy
    end
  rescue Exception => e
    Chef::Log.warn("We can't proceed to destroy the Build Nodes.")
    Chef::Log.warn("We couldn't get the chef-server Public IP: #{e.message}")
  end
else
  log 'Skipping Build Nodes deletion because missing delivery.pem key'
end
