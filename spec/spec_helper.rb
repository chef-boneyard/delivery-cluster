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
require 'chef/node'
require 'chef/server_api'

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

  let(:vagrant_data) do
    {
      'vm_box' => 'opscode-ubuntu-14.04',
      'image_url' => 'https://opscode-bento.com/opscode_ubuntu-14.04.box',
      'vm_memory' => '2048',
      'vm_cpus' => '2',
      'key_file' => '/Users/afiune/.vagrant.d/insecure_private_key',
      'use_private_ip_for_ssh' => false,
      'bootstrap_proxy' => 'http://my-proxy.com/',
      'chef_config' => "http_proxy 'http://my-proxy.com/'\nno_proxy 'localhost'",
      'chef_version' => '12.0.0',
      'install_sh_path' => '/custom/path/awesome_install.sh'
    }
  end

  let(:aws_data) do
    {
      'flavor' => 'c3.xlarge',
      'image_id' => 'ami-3d50120d',
      'key_name' => 'afiune',
      'subnet_id' => 'subnet-19ac017c',
      'ssh_username' => 'ubuntu',
      'security_group_ids' => 'sg-cbacf8ae',
      'use_private_ip_for_ssh' => true,
      'bootstrap_proxy' => 'http://my-proxy.com/',
      'chef_config' => "http_proxy 'http://my-proxy.com/'\nno_proxy 'localhost'",
      'install_sh_path' => '/wrong_place.sh'
    }
  end
end

# Common shared data
module SharedCommonData
  extend RSpec::SharedContext

  let(:cluster_data) do
    {
      'id' => 'chefspec',
      'trusted_certs' => {},
      'chef-server' => {
        'organization' => 'chefspec',
        'fqdn' => 'chef-server.chef.io',
        'host' => 'chef-server.chef.io',
        'existing' => false,
        'aws_tags' => {
          'cool_tag' => 'awesomeness',
          'important' => 'thing'
        }
      },
      'delivery' => {
        'version' => 'latest',
        'fqdn' => 'delivery-server.chef.io',
        'host' => 'delivery-server.chef.io',
        'enterprise' => 'chefspec',
        'artifactory' => false,
        'config' => "nginx['enable_non_ssl'] = true",
        'license_file' => '/Users/afiune/delivery.license'
      },
      'analytics' => {
        'fqdn' => 'analytics-server.chef.io',
        'host' => 'analytics-server.chef.io'
      },
      'supermarket' => {
        'fqdn' => 'supermarket-server.chef.io',
        'host' => 'supermarket-server.chef.io'
      },
      'splunk' => {
        'fqdn' => 'splunk-server.chef.io',
        'host' => 'splunk-server.chef.io'
      },
      'builders' => {
        'count' => '3',
        'delivery-cli' => {}
      }
    }
  end
  let(:rest) do
    Chef::ServerAPI.new(
      'https://chef-server.chef.io/organizations/chefspec',
      client_name: 'delivery',
      signing_key_filename: File.expand_path('spec/unit/mock/delivery.pem')
    )
  end
  let(:chef_node) do
    {
      'normal' => {
        'delivery-cluster' => {
          'driver' => 'ssh',
          'ssh' => {}
        },
        'ipaddress' => '10.1.1.1'
      },
      'recipes' => []
    }
  end
  let(:delivery_node) do
    {
      'normal' => {
        'delivery-cluster' => {
          'driver' => 'vagrant',
          'vagrant' => {}
        },
        'ipaddress' => '10.1.1.2'
      },
      'recipes' => []
    }
  end
  let(:supermarket_node) do
    {
      'normal' => {
        'delivery-cluster' => {
          'driver' => 'aws',
          'aws' => {}
        },
        'ec2' => {
          'local_ipv4' => '10.1.1.3'
        },
        'ipaddress' => '10.1.1.3'
      },
      'recipes' => []
    }
  end
  let(:analytics_node) do
    {
      'normal' => {
        'delivery-cluster' => {
          'driver' => 'ssh',
          'ssh' => {}
        },
        'ipaddress' => '10.1.1.4'
      },
      'recipes' => []
    }
  end
  let(:splunk_node) do
    {
      'normal' => {
        'delivery-cluster' => {
          'driver' => 'vagrant',
          'vagrant' => {}
        },
        'ipaddress' => '10.1.1.5'
      },
      'recipes' => []
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
