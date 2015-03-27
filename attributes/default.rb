#
# Cookbook Name:: delivery-cluster
# Attributes:: default
#
# Author:: Salim Afiune (<afiune@chef.io>)
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

# => The Cluste Name which will be use to define all default hostnames
default['delivery-cluster']['id'] = nil

# Specific attributes
# => Delivery Server
default['delivery-cluster']['delivery']['hostname']    = nil
default['delivery-cluster']['delivery']['fqdn']        = nil
default['delivery-cluster']['delivery']['flavor']      = 't2.medium'
default['delivery-cluster']['delivery']['enterprise']  = 'my_enterprise'

# => pass-through
# This attribute will allow the Artifact pass-through the delivery server.
# This feature requires that the delivery server has VPN Access.
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
default['delivery-cluster']['delivery']['ldap']        = {}

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
default['delivery-cluster']['chef-server']['hostname']     = nil
default['delivery-cluster']['chef-server']['organization'] = 'my_enterprise'
default['delivery-cluster']['chef-server']['flavor']       = 't2.medium'

# => Analytics Server (Not Required)
#
# In order to provision an Analytics Server you have to first provision the entire
# `delivery-cluster::setup` after that, you are ready to run `delivery-cluster::setup_analytics`
# that will activate analytics.
default['delivery-cluster']['analytics']['hostname']  = nil
default['delivery-cluster']['analytics']['fqdn']      = nil
default['delivery-cluster']['analytics']['feature']   = 'false'
default['delivery-cluster']['analytics']['flavor']    = 't2.medium'

# Splunk Server
default['delivery-cluster']['splunk']['hostname_prefix'] = nil
default['delivery-cluster']['splunk']['username']        = 'admin'
default['delivery-cluster']['splunk']['password']        = nil
default['delivery-cluster']['splunk']['flavor']          = 'c3.large'

# => Build Nodes
default['delivery-cluster']['builders']['hostname_prefix']     = nil
default['delivery-cluster']['builders']['count']               = 3
default['delivery-cluster']['builders']['flavor']              = 't2.small'
default['delivery-cluster']['builders']['additional_run_list'] = []
