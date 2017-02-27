#
# Cookbook Name:: delivery-cluster
# Spec:: ssh_spec
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

describe DeliveryCluster::Provisioning::Ssh do
  let(:node) { Chef::Node.new }
  let(:ssh_object) { described_class.new(node) }

  before do
    node.default['delivery-cluster'] = cluster_data
    node.default['ipaddress'] = '33.33.33.10'
  end

  context 'when driver attributes are NOT implemented' do
    it 'raise an error' do
      expect { ssh_object }.to raise_error(RuntimeError)
    end
  end

  context 'when driver attributes are implemented' do
    before do
      node.default['delivery-cluster']['ssh'] = ssh_data
    end

    it 'returns the right driver name' do
      expect(ssh_object.driver).to eq 'ssh'
    end

    it 'returns the right driver username' do
      expect(ssh_object.username).to eq 'ubuntu'
    end

    it 'returns the ipaddress' do
      expect(ssh_object.ipaddress(node)).to eq '33.33.33.10'
    end

    it 'returns the right machine_options:Hash' do
      expect(ssh_object.machine_options).to eq(
        convergence_options: {
          bootstrap_proxy: ssh_data['bootstrap_proxy'],
          chef_config: ssh_data['chef_config'],
          chef_version: ssh_data['chef_version'],
          install_sh_path: ssh_data['install_sh_path'],
        },
        transport_options: {
          username: ssh_data['ssh_username'],
          ssh_options: {
            user: ssh_data['ssh_username'],
            password: nil,
            keys: [ssh_data['key_file']],
          },
          options: {
            prefix: ssh_data['prefix'],
          },
        }
      )
    end

    context 'and we specify both password and key_file' do
      before do
        node.default['delivery-cluster']['ssh']['password'] = 'sup3rs3cur3'
      end

      it 'raise an error' do
        expect { ssh_object }.to raise_error(RuntimeError)
      end
    end

    describe '#specific_machine_options' do
      it 'returns the chef-server specific_machine_options' do
        expect(ssh_object.specific_machine_options('chef-server')).to eq(
          [{
            transport_options: {
              host: 'chef-server.chef.io',
            },
          }]
        )
      end

      context 'with NO builders specs' do
        it 'returns an empty array for the builder 1' do
          expect(ssh_object.specific_machine_options('builders', 1)).to eq([])
        end
      end

      context 'with builders specs' do
        before do
          node.default['delivery-cluster']['builders']['1'] = { 'ip' => '33.33.33.20' }
        end
        it 'returns the ipaddress of the builder 1' do
          expect(ssh_object.specific_machine_options('builders', 1)).to eq(
            [{
              transport_options: {
                ip_address: '33.33.33.20',
              },
            }]
          )
        end
      end
    end
  end
end
