#
# Cookbook Name:: delivery-cluster
# Attributes:: default
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

#
# General AWS Attributes
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
default['delivery-cluster']['aws']['use_private_ip_for_ssh']  = false

# => The Cluste Name which will be use to define all the server names
default['delivery-cluster']['id'] = 'test'

# Specific attributes
# => Delivery Server
default['delivery-cluster']['delivery']['hostname']    = "delivery-server-#{node['delivery-cluster']['id']}"
default['delivery-cluster']['delivery']['flavor']      = 't2.medium'
default['delivery-cluster']['delivery']['enterprise']  = 'my_enterprise'

# Delivery Artifacts
#
# There are three ways you can specify the Delivery Artifact
# 1) If you want to deploy the latest Delivery Build set the version to 'latest'
#    remember that this depend on Chef VPN Access
# => default['delivery-cluster']['delivery']['version'] = 'latest'
#
# 2) If you want to deploy a specific version you can also specify it
#    and it will pull it down from artifactory. VPN Access Needed!
#    To see the available versions go to:
#      * http://artifactory.chef.co/webapp/browserepo.html?4&pathId=omnibus-current-local:com/getchef/delivery
# => default['delivery-cluster']['delivery']['version']             = '0.2.21'
#
# 3) If you have the artifact URI you can specify it also and
#    this way you don't depend on VPN Access
# => default['delivery-cluster']['delivery']['version']             = '0.1.0_alpha.132'
# => default['delivery-cluster']['delivery']['debian']['artifact']  = 'https://s3.amazonaws.com/chef-delivery/dev/delivery-0.1.0_alpha.132%2B20141126080809-1.x86_64.rpm'
# => default['delivery-cluster']['delivery']['debian']['checksum']  = 'b279a4c7c0d277b9ec3f939c92a50970154eb7e56ddade4c2d701036aa27ee71'
#
default['delivery-cluster']['delivery']['version'] = 'latest'

# => Chef Server
default['delivery-cluster']['chef-server']['hostname']     = "chef-server-#{node['delivery-cluster']['id']}"
default['delivery-cluster']['chef-server']['organization'] = 'my_enterprise'
default['delivery-cluster']['chef-server']['flavor']       = 't2.small'

# => Build Nodes
default['delivery-cluster']['builders']['hostname_prefix'] = "build-node-#{node['delivery-cluster']['id']}"
default['delivery-cluster']['builders']['role']            = 'delivery_builders'
default['delivery-cluster']['builders']['count']           = 3
default['delivery-cluster']['builders']['flavor']          = 't2.small'
