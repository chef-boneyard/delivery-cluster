#
# Cookbook Name:: delivery-cluster
# Recipe:: destroy_delivery_dr
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

    # Destroy Delivery Standby Server
    machine delivery_server_dr_hostname do
      action :destroy
    end
  rescue StandardError => e
    Chef::Log.warn("We can't proceed to destroy the Delivery Standby Server.")
    Chef::Log.warn("We couldn't get the chef-server Public/Private IP: #{e.message}")
  end
else
  log 'Skipping Delivery Standby Server deletion because missing delivery.pem key'
end
