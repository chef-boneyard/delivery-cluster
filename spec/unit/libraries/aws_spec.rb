#
# Cookbook Name:: delivery-cluster
# Spec:: aws_spec
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

describe DeliveryCluster::Provisioning::Aws do
  let(:node) { Chef::Node.new }
  let(:aws_object) { described_class.new(node) }

  before do
    node.default['delivery-cluster']   = {}
    node.default['ec2']['local_ipv4']  = '10.223.1.33'
    node.default['ec2']['public_ipv4'] = '192.168.1.2'
  end

  context 'when driver attributes are NOT implemented' do
    it 'raise an error' do
      expect { aws_object }.to raise_error(RuntimeError)
    end
  end

  context 'when driver attributes are implemented' do
    before do
      node.default['delivery-cluster']['aws'] = aws_data
    end

    it 'returns the right driver name' do
      expect(aws_object.driver).to eq 'aws'
    end

    it 'returns the right driver username' do
      expect(aws_object.username).to eq 'ubuntu'
    end

    it 'returns the private_ipaddress' do
      expect(aws_object.ipaddress(node)).to eq '10.223.1.33'
    end

    it 'returns the right machine_options:Hash' do
      expect(aws_object.machine_options).to eq(
        convergence_options: {
          bootstrap_proxy: aws_data['bootstrap_proxy'],
          chef_config: aws_data['chef_config'],
          chef_version: aws_data['chef_version'],
          install_sh_path: aws_data['install_sh_path'],
        },
        bootstrap_options: {
          instance_type:      aws_data['flavor'],
          key_name:           aws_data['key_name'],
          subnet_id:          aws_data['subnet_id'],
          security_group_ids: aws_data['security_group_ids'],
        },
        ssh_username:           aws_data['ssh_username'],
        image_id:               aws_data['image_id'],
        use_private_ip_for_ssh: aws_data['use_private_ip_for_ssh']
      )
    end

    context 'and we set use_private_ip_for_ssh to false ' do
      before do
        node.default['delivery-cluster']['aws']['use_private_ip_for_ssh'] = false
      end

      it 'returns the public_ipaddress' do
        expect(aws_object.ipaddress(node)).to eq '192.168.1.2'
      end
    end

    context 'and components has specific attributes' do
      before do
        node.default['delivery-cluster'] = cluster_data
        node.default['delivery-cluster']['aws'] = aws_data
      end

      it 'returns the right specific_machine_options for chef_server' do
        expect(aws_object.specific_machine_options('chef-server')).to eq [
          {
            aws_tags: {
              'cool_tag' => 'awesomeness',
              'important' => 'thing',
            },
          },
        ]
      end
    end
  end
end
