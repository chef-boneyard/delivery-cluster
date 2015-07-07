#
# Cookbook Name:: delivery-cluster
# Spec:: spec_helper
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

require 'chefspec'
require 'chefspec/berkshelf'

TOPDIR = File.expand_path(File.join(File.dirname(__FILE__), '..'))
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

# Include all our libraries
Dir['libraries/*.rb'].each { |f| require File.expand_path(f) }

# Provisioning Drivers Data
module SharedDriverData
  extend RSpec::SharedContext

  let(:ssh_data) do
    {
      'ssh_username' => 'ubuntu',
      'prefix' => 'gksudo ',
      'key_file' => '/Users/afiune/.vagrant.d/insecure_private_key',
      'bootstrap_proxy' => 'http://my-proxy.com/',
      'chef_config' => "http_proxy 'http://my-proxy.com/'\nno_proxy 'localhost'",
      'chef_version' => '12.3.0'
    }
  end

  let(:vagrant_driver) do
    {
      'vm_box' => 'opscode-ubuntu-14.04',
      'image_url' => 'https://opscode-bento.com/opscode_ubuntu-14.04.box',
      'vm_memory' => '2048',
      'vm_cpus' => '2',
      'key_file' => '/Users/afiune/.vagrant.d/insecure_private_key',
      'use_private_ip_for_ssh' => false,
      'bootstrap_proxy' => 'http://my-proxy.com/',
      'chef_config' => "http_proxy 'http://my-proxy.com/'\nno_proxy 'localhost'",
      'chef_version' => '12.0.0'
    }
  end

  let(:aws_driver) do
    {
      'flavor' => 'c3.xlarge',
      'image_id' => 'ami-3d50120d',
      'key_name' => 'afiune',
      'subnet_id' => 'subnet-19ac017c',
      'ssh_username' => 'ubuntu',
      'security_group_ids' => 'sg-cbacf8ae',
      'use_private_ip_for_ssh' => true,
      'bootstrap_proxy' => 'http://my-proxy.com/',
      'chef_config' => "http_proxy 'http://my-proxy.com/'\nno_proxy 'localhost'"
    }
  end
end

# Common shared data
module SharedCommonData
  extend RSpec::SharedContext

  let(:cluster_data) do
    {
      'id' => 'chefspec',
      'chef-server' => {
        'organization' => '',
        'existing' => false
      },
      'delivery' => {
        'version' => 'latest',
        'enterprise' => 'chefspec',
        'artifactory' => false,
        'config' => "nginx['enable_non_ssl'] = true",
        'license_file' => '/Users/afiune/delivery.license'
      },
      'builders' => {
        'count' => '3',
        '1' => {},
        '2' => {},
        '3' => {}
      }
    }
  end
end

RSpec.configure do |config|
  config.include SharedDriverData
  config.include SharedCommonData
  config.filter_run_excluding ignore: true
  config.platform = 'ubuntu'
  config.version = '14.04'
end
