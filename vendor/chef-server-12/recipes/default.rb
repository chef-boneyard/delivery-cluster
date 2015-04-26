#
# Cookbook Name:: chef-server-12
# Recipe:: default
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

directory "/etc/opscode" do
  recursive true
end

chef_server_ingredient 'chef-server-core' do
  notifies :reconfigure, 'chef_server_ingredient[chef-server-core]'
end

template "/etc/opscode/chef-server.rb" do
  owner "root"
  mode "0644"
  notifies :run, "execute[reconfigure chef]", :immediately
end

execute "reconfigure chef" do
  command "chef-server-ctl reconfigure"
  action :nothing
end

# Install Enabled Plugins
node['chef-server-12']['plugin'].each do |feature, enabled|
  install_plugin(feature) if enabled
end

# Delivery Setup?
include_recipe "chef-server-12::delivery_setup" if node['chef-server-12']['delivery_setup']
