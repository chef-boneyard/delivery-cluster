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

require 'chef/provisioning/aws_driver'

with_driver 'aws'

# Only if we have the credentials to destroy it
if File.exist?("#{tmp_infra_dir}/delivery.pem")
  begin
    # Setting the new Chef Server we just created
    with_chef_server chef_server_url,
      client_name: 'delivery',
      signing_key_filename: "#{tmp_infra_dir}/delivery.pem"

    # Destroy Delivery Server
    machine delivery_server_hostname do
      action :destroy
    end

    # Delivery is gone. Why do we need the keys?
    # => Org & Delivery User Keys
    execute 'Deleting Delivery User Keys' do
      command "rm -rf #{tmp_infra_dir}/delivery.pem"
      action :run
    end

    # => Enterprise Creds
    execute 'Deleting Validator & Delivery User Keys' do
      command "rm -rf #{tmp_infra_dir}/#{node['delivery-cluster']['delivery']['enterprise']}.creds"
      action :run
    end
  rescue Exception => e
    Chef::Log.warn("We can't proceed to destroy the Delivery Server.")
    Chef::Log.warn("We couldn't get the chef-server Public/Private IP: #{e.message}")
  end
else
  log 'Skipping Delivery Server deletion because missing delivery.pem key'
end
