#
# Cookbook Name:: delivery-cluster
# Recipe:: destroy_splunk
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

include_recipe 'delivery-cluster::_settings'

if splunk_enabled?
  begin
    with_chef_server chef_server_url,
                     client_name: 'delivery',
                     signing_key_filename: "#{cluster_data_dir}/delivery.pem"

    directory "#{current_dir}/data_bags/vault" do
      recursive true
      action :delete
    end

    %W(
      #{cluster_data_dir}/splunk.key
      #{cluster_data_dir}/splunk.csr
      #{cluster_data_dir}/splunk.crt
    ).each do |f|
      file f do
        action :delete
      end
    end

    # Delete Splunk ChefVault
    execute 'Creating Splunk ChefVault' do
      cwd current_dir
      command 'knife data bag delete vault -y'
      only_if 'knife data bag show vault'
      action :run
    end

    # Kill the machine
    machine splunk_server_hostname do
      action :destroy
    end

    # Delete the lock file
    File.delete(splunk_lock_file)
  rescue StandardError => e
    Chef::Log.warn("We can't proceed to destroy Splunk Sever: #{e.message}")
  end
end
