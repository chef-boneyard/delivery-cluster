#
# Cookbook Name:: delivery-cluster
# Recipe:: destroy_builders
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
    # Only if there is an active chef server
    chef_node = Chef::Node.load(chef_server_hostname)
    chef_server_ip = chef_node['ec2']['public_ipv4']

    # Setting the new Chef Server we just created
    with_chef_server "https://#{chef_server_ip}/organizations/#{node['delivery-cluster']['chef-server']['organization']}",
      client_name: "delivery",
      signing_key_filename: "#{tmp_infra_dir}/delivery.pem"

    # Destroy Build Nodes
    machine_batch "Destroying Build Nodes" do
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
  log "Skipping Build Nodes deletion because missing delivery.pem key"
end
