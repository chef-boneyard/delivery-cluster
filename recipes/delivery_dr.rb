#
# Cookbook Name:: delivery-cluster
# Recipe:: delivery_dr
#
# Author:: Jon Morrow (<jmorrow@chef.io>)
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

# Phase 1 Lay down keys and append authorized_Keys
ssh_dir = '/opt/delivery/embedded/.ssh' ## Assuming the directory since we don't modify it.
directory ssh_dir do
  owner 'delivery'
  mode 0700
end

primary_keys = Chef::EncryptedDataBagItem.load('keys', 'delivery_primary_keys')
standby_keys = Chef::EncryptedDataBagItem.load('keys', 'delivery_standby_keys')

if node['delivery-cluster']['delivery']['primary']
  file "#{ssh_dir}/id_rsa" do
    content primary_keys['private_key']
    owner 'delivery'
    mode 0600
  end

  file "#{ssh_dir}/id_rsa.pub" do
    content primary_keys['public_key']
    owner 'delivery'
    mode 0644
  end
else
  file "#{ssh_dir}/id_rsa" do
    content standby_keys['private_key']
    owner 'delivery'
    mode 0600
  end

  file "#{ssh_dir}/id_rsa.pub" do
    content standby_keys['public_key']
    owner 'delivery'
    mode 0644
  end

  file "#{ssh_dir}/authorized_keys" do
    content primary_keys['public_key']
    owner 'delivery'
    mode 0600
  end
end
