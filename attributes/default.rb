#
# Cookbook Name:: delivery-cluster
# Attributes:: default
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Provisioning Driver
default['delivery-cluster']['driver'] = 'vagrant'

# AWS Driver Attributes
#
# In addition to this set of attributes you MUST have a ~/.aws/config file like this:
# => $ vi ~/.aws/config
# => [default]
# => region = us-east-1
# => aws_access_key_id = YOUR_ACCESS_KEY_ID
# => aws_secret_access_key = YOUR_SECRET_KEY
default['delivery-cluster']['aws']['key_name']                = ENV['USER']
default['delivery-cluster']['aws']['ssh_username']            = nil
default['delivery-cluster']['aws']['security_group_ids']      = nil
default['delivery-cluster']['aws']['image_id']                = nil
default['delivery_cluster']['aws']['subnet_id']               = nil
default['delivery-cluster']['aws']['bootstrap_proxy']         = ENV['HTTPS_PROXY'] || ENV['HTTP_PROXY']
default['delivery_cluster']['aws']['chef_config']             = nil
default['delivery_cluster']['aws']['chef_version']            = nil
default['delivery-cluster']['aws']['use_private_ip_for_ssh']  = false

# SSH Driver Attributes
default['delivery-cluster']['ssh']['key_file']                = nil
default['delivery-cluster']['ssh']['prefix']                  = nil
default['delivery-cluster']['ssh']['ssh_username']            = nil
default['delivery-cluster']['ssh']['bootstrap_proxy']         = ENV['HTTPS_PROXY'] || ENV['HTTP_PROXY']
default['delivery_cluster']['ssh']['chef_config']             = nil
default['delivery_cluster']['ssh']['chef_version']            = nil
default['delivery-cluster']['ssh']['use_private_ip_for_ssh']  = false

# Vagrant Driver Attributes
default['delivery-cluster']['vagrant']['key_file']            = nil
default['delivery-cluster']['vagrant']['prefix']              = nil
default['delivery-cluster']['vagrant']['ssh_username']        = nil
default['delivery_cluster']['vagrant']['vm_box']              = nil
default['delivery_cluster']['Vagrant']['image_url']           = nil
default['delivery_cluster']['Vagrant']['vm_memory']           = nil
default['delivery_cluster']['Vagrant']['vm_cpus']             = nil
default['delivery_cluster']['vagrant']['network']             = nil
default['delivery-cluster']['vagrant']['key_file']            = nil
default['delivery_cluster']['vagrant']['chef_config']         = nil
default['delivery_cluster']['vagrant']['chef_version']        = nil

# Azure Driver Attributes
default['delivery-cluster']['azure']['ssh_username']            = nil
default['delivery-cluster']['azure']['use_private_ip_for_ssh']  = false

# => The Cluster Name which will be use to define all default hostnames
default['delivery-cluster']['id'] = nil

# => Common Cluster Recipes
#
# Add any recipe that you need to add to the run_list of all the servers
# of the delivery-cluster.
#
# As an example:
# * We would like to aply a security policy to every server on the cluster
#   'security_policies::lock_root_login' locks down root login
#
# This attribute would look like:
# default['delivery-cluster']['common_cluster_recipes'] = ['security_policies::lock_root_login']
default['delivery-cluster']['common_cluster_recipes'] = []

# List of Trusted Certificates to add to chefdk
#
# You need to store the certificates inside `.chef/trusted_certs` within `delivery-cluster`
# repository and then list them in the below attribute as the following example:
# {
#   'Proxy Cert': 'my_proxy.cer',
#   'Corp Cert': 'corporate.crt',
#   'Open Cert': 'other_open.crt'
# }
default['delivery-cluster']['trusted_certs'] = {}

# Delivery License
# => Delivery requires a license in able to install properly. This license needs to
#    be put on the server prior to installation of Delivery otherwise
#    `delivery-ctl reconfigure` will fail. Specify the path to a local copy of the
#    delivery.license file to have it synced to your Delivery Server.
default['delivery-cluster']['delivery']['license_file'] = nil

# Specific attributes
# => Delivery Server
default['delivery-cluster']['delivery']['hostname']        = nil
default['delivery-cluster']['delivery']['fqdn']            = nil
default['delivery-cluster']['delivery']['chef_server']     = nil
default['delivery-cluster']['delivery']['flavor']          = 't2.medium'
default['delivery-cluster']['delivery']['enterprise']      = 'my_enterprise'
default['delivery-cluster']['delivery']['recipes']         = []
default['delivery-cluster']['delivery']['attributes']      = {}

# => pass-through
# This attribute will allow the Artifact pass-through the delivery server.
# This feature requires that the delivery server has VPN Access.
#
# NOTE: If your delivery server does NOT have access to Chef VPN you have to
# set this to `false` so it can download the artifact locally and then
# upload it to the delivery server.
default['delivery-cluster']['delivery']['pass-through'] = true

# => LDAP config
# => Available Attributes
#   => ldap_hosts
#   => ldap_port
#   => ldap_timeout
#   => ldap_base_dn
#   => ldap_bind_dn
#   => ldap_bind_dn_password
#   => ldap_encryption
#   => ldap_attr_login
#   => ldap_attr_mail
#   => ldap_attr_full_name
default['delivery-cluster']['delivery']['ldap'] = {}

# => Custom config
#
# Specify custom configuration for the `delivery.rb` like:
# => default['delivery-cluster']['delivery']['config'] = "nginx['enable_non_ssl'] = true"
default['delivery-cluster']['delivery']['config'] = nil

# Delivery Artifacts
#
# There are three ways you can specify the Delivery Artifact
# 1) If you want to deploy the latest Delivery Build set the version to
#    'latest' and we will pull it down from `packagecloud`
# => default['delivery-cluster']['delivery']['version'] = 'latest'
#    Note that will pull from stable packages; if you want to pull from
#    bleeding edge, untested packages (not recommended!), please use
# => default['delivery-cluster']['delivery']['release-channel'] = 'current'
#
# 2) If you want to deploy a specific version you can also specify it
#    To see the available versions go to:
#      * https://packagecloud.io/chef/current
# => default['delivery-cluster']['delivery']['version']   = '0.3.9'
#
# 3) You can also specify the artifact
#
# => default['delivery-cluster']['delivery']['version']   = '0.3.7'
# => default['delivery-cluster']['delivery']['artifact']  = 'http://my.delivery.pkg'
# => default['delivery-cluster']['delivery']['checksum']  = '123456789ABCDEF'
#
default['delivery-cluster']['delivery']['version']          = 'latest'
default['delivery-cluster']['delivery']['release-channel']  = 'stable'

# Use Chef Artifactory (Requires Chef VPN)
default['delivery-cluster']['delivery']['artifactory'] = false

# Enable Insights on Delivery
default['delivery-cluster']['delivery']['insights']['enable'] = false

# => Chef Server
default['delivery-cluster']['chef-server']['hostname']     = nil
default['delivery-cluster']['chef-server']['fqdn']         = nil
default['delivery-cluster']['chef-server']['organization'] = 'my_enterprise'
default['delivery-cluster']['chef-server']['flavor']       = 't2.medium'
default['delivery-cluster']['chef-server']['existing']     = false
default['delivery-cluster']['chef-server']['recipes']      = []
default['delivery-cluster']['chef-server']['attributes']   = {}

# Password of the Delivery User in the Chef Server
#
# Change this attribute to customize the password of the delivery user
# inside the chef-server. If nil, `delivery-cluster` will automatically
# generate a random password.
default['delivery-cluster']['chef-server']['delivery_password'] = nil

# By changing the chef-zero run port we can now enable opscode-reporting
# See .chef/knife.rb
default['delivery-cluster']['chef-server']['enable-reporting'] = true

# => Analytics Server (Not Required)
#
# In order to provision an Analytics Server you have to first provision the entire
# `delivery-cluster::setup` after that, you are ready to run `delivery-cluster::setup_analytics`
# that will activate analytics.
default['delivery-cluster']['analytics']['hostname']   = nil
default['delivery-cluster']['analytics']['fqdn']       = nil
default['delivery-cluster']['analytics']['features']   = 'false'
default['delivery-cluster']['analytics']['flavor']     = 't2.medium'
default['delivery-cluster']['analytics']['attributes'] = {}

# Splunk Server
default['delivery-cluster']['splunk']['hostname_prefix'] = nil
default['delivery-cluster']['splunk']['username']        = 'admin'
default['delivery-cluster']['splunk']['password']        = nil
default['delivery-cluster']['splunk']['flavor']          = 'c3.large'

# Supermarket Server
default['delivery-cluster']['supermarket'] = nil

# => Build Nodes
default['delivery-cluster']['builders']['hostname_prefix']     = nil
default['delivery-cluster']['builders']['count']               = 3
default['delivery-cluster']['builders']['flavor']              = 't2.small'
default['delivery-cluster']['builders']['additional_run_list'] = []
default['delivery-cluster']['builders']['attributes']          = {}

# Optional Hash of delivery-cli
#
# You can specify a delivery-cli artifact passing the following attributes:
# => {
#      "version":  "0.3.0",
#      "artifact": "http://my.delivery-cli.pkg",
#      "checksum": "123456789ABCDEF"
#    }
default['delivery-cluster']['builders']['delivery-cli']        = {}

# Optional ChefDK version
default['delivery-cluster']['builders']['chefdk_version']      = nil
