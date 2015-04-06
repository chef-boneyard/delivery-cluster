#
# Cookbook Name:: delivery-cluster
# Recipe:: destroy_delivery
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

# Starting to abstract the specific configurations by providers
include_recipe 'delivery-cluster::_settings'

# Only if we have the credentials to destroy it
if File.exist?("#{cluster_data_dir}/delivery.pem")
  begin
    # Setting the new Chef Server we just created
    with_chef_server chef_server_url,
      client_name: 'delivery',
      signing_key_filename: "#{cluster_data_dir}/delivery.pem"

    # Destroy Delivery Server
    machine delivery_server_hostname do
      action :destroy
    end

    # Delete Enterprise Creds
    file File.join(cluster_data_dir, "#{node['delivery-cluster']['delivery']['enterprise']}.creds") do
      action :delete
    end
  rescue Exception => e
    Chef::Log.warn("We can't proceed to destroy the Delivery Server.")
    Chef::Log.warn("We couldn't get the chef-server Public/Private IP: #{e.message}")
  end
else
  log 'Skipping Delivery Server deletion because missing delivery.pem key'
end
