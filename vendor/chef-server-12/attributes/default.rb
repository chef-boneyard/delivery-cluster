#
# Cookbook Name:: chef-server-12
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

default['chef-server-12']['version']       = 'latest'

# Plugins / Feautures
#
# To Install plugins into the Chef-Server simply enable them setting the value `true`
# If there is more plugins you just need to add them as follow:
# => default['chef-server-12']['plugin']['PLUGIN_NAME'] = true
default['chef-server-12']['plugin']['manage']       = true
default['chef-server-12']['plugin']['reporting']    = true
default['chef-server-12']['plugin']['push-server']  = true
default['chef-server-12']['plugin']['chef-sync']    = false

# Chef Server Parameters
default['chef-server-12']['api_fqdn']     = node['ipaddress']
default['chef-server-12']['topology']     = 'standalone'
default['chef-server-12']['extra_config'] = nil

# Analytics Server Parameters
default['chef-server-12']['analytics'] = nil

# Supermarket Server Parameters
default['chef-server-12']['supermarket'] = nil

# Delivery Server
#
# This section is dedicated to setup the basic requirements for delivery-server
# to work. If you do not need this configuration you just need to:
# => Set ['chef-server-12']['delivery_setup'] to `false`
#
# This process includes:
# => Create an organization
# => Create the delivery user
# => Save keys into the server and/or a databag. (['chef-server-12']['store_keys_databag'])
#
# TODO: Figure out how to make delivery user an admin (tricky)
default['chef-server-12']['delivery_setup']            = true
default['chef-server-12']['store_keys_databag']        = true
default['chef-server-12']['delivery']['ssl']           = true
default['chef-server-12']['delivery']['organization']  = "chef_delivery"
default['chef-server-12']['delivery']['org_longname']  = "\"Chef Continuous Delivery\""
default['chef-server-12']['delivery']['user']          = "delivery"
default['chef-server-12']['delivery']['name']          = "Delivery"
default['chef-server-12']['delivery']['last_name']     = "User"
default['chef-server-12']['delivery']['email']         = "delivery@getchef.com"
default['chef-server-12']['delivery']['password']      = "delivery"
default['chef-server-12']['delivery']['validator_pem'] = "/tmp/validator.pem"
default['chef-server-12']['delivery']['delivery_pem']  = "/tmp/delivery.pem"
default['chef-server-12']['delivery']['db']            = "delivery"
default['chef-server-12']['delivery']['item']          = "delivery_pem"
