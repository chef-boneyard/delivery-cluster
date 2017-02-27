#
# Cookbook Name:: delivery-cluster
# Spec:: vagrant_spec
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

require 'spec_helper'

describe DeliveryCluster::Provisioning::Vagrant do
  let(:node) { Chef::Node.new }
  let(:vagrant_object) { described_class.new(node) }

  before do
    node.default['delivery-cluster'] = {}
    node.default['ipaddress'] = '10.1.1.2'
  end

  context 'when driver attributes are NOT implemented' do
    it 'raise an error' do
      expect { vagrant_object }.to raise_error(RuntimeError)
    end
  end

  context 'when driver attributes are implemented' do
    before do
      node.default['delivery-cluster']['vagrant'] = vagrant_data
    end

    it 'returns the right driver name' do
      expect(vagrant_object.driver).to eq 'vagrant'
    end

    it 'returns the right driver username' do
      expect(vagrant_object.username).to eq 'vagrant'
    end

    it 'returns the private_ipaddress' do
      expect(vagrant_object.ipaddress(node)).to eq '10.1.1.2'
    end

    it 'returns the right machine_options:Hash' do
      expect(vagrant_object.machine_options).to eq(
        convergence_options: {
          bootstrap_proxy: vagrant_data['bootstrap_proxy'],
          chef_config: vagrant_data['chef_config'],
          chef_version: vagrant_data['chef_version'],
          install_sh_path: vagrant_data['install_sh_path'],
        },
        vagrant_options: {
          'vm.box' => vagrant_data['vm_box'],
          'vm.box_url' => vagrant_data['image_url'],
          'vm.hostname' => vagrant_data['vm_hostname'],
        },
        vagrant_config: vagrant_data['vagrant_config'],
        transport_options: {
          options: {
            prefix: 'sudo ',
          },
        },
        use_private_ip_for_ssh: vagrant_data['use_private_ip_for_ssh']
      )
    end
  end
end
