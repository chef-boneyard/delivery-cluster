#
# Cookbook Name:: delivery-cluster
# Recipe:: destroy_splunk
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'delivery-cluster::_aws_settings'

# TODO: This should be moved out
begin
  with_chef_server chef_server_url,
    client_name: 'delivery',
    signing_key_filename: "#{cluster_data_dir}/delivery.pem"

  directory "#{current_dir}/data_bags/vault" do
    action :delete
  end

  %W{
    #{cluster_data_dir}/splunk.key
    #{cluster_data_dir}/splunk.csr
    #{cluster_data_dir}/splunk.crt
  }.each do |f|
    file f do
      action :delete
    end
  end

  # Delete Splunk ChefVault
  execute 'Creating Splunk ChefVault' do
    cwd current_dir
    command "knife data bag delete vault -y"
    only_if "knife data bag show vault"
    action :run
  end

  # Kill the machine
  machine splunk_server_hostname do
    action :destroy
  end

  # Delete the lock file
  File.delete(splunk_lock_file)
rescue Exception => e
  Chef::Log.warn("We can't proceed to destroy Splunk Sever: #{e.message}")
end
