#
# Cookbook Name:: delivery-cluster
# Spec:: helpers_component_spec
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

describe DeliveryCluster::Helpers::Component do
  let(:node) { Chef::Node.new }
  let(:chef_node) do
    n = Chef::Node.new
    n.default['delivery-cluster']['driver'] = 'ssh'
    n.default['delivery-cluster']['ssh'] = {}
    n.default['ipaddress'] = '10.1.1.1'
    n
  end
  let(:delivery_node) do
    n = Chef::Node.new
    n.default['delivery-cluster']['driver'] = 'vagrant'
    n.default['delivery-cluster']['vagrant'] = {}
    n.default['ipaddress'] = '10.1.1.2'
    n
  end
  let(:rest) do
    Chef::REST.new(
      'https://chef-server.chef.io/organizations/chefspec',
      'delivery',
      File.expand_path('spec/unit/mock/delivery.pem')
    )
  end
  before do
    allow(Chef::Node).to receive(:load).and_return(Chef::Node.new)
    allow(Chef::REST).to receive(:new).and_return(rest)
    allow_any_instance_of(Chef::REST).to receive(:get_rest)
      .with("nodes/chef-server-chefspec")
      .and_return(chef_node)
    allow_any_instance_of(Chef::REST).to receive(:get_rest)
      .with("nodes/delivery-server-chefspec")
      .and_return(delivery_node)
  end

  context 'when fqdn' do
    before { node.default['delivery-cluster'] = cluster_data }

    context 'is speficied' do
      it 'should return chef-server component fqdn' do
        expect(described_class.component_fqdn(node, 'chef-server')).to eq cluster_data['chef-server']['fqdn']
      end

      it 'should return delivery component fqdn' do
        expect(described_class.component_fqdn(node, 'delivery')).to eq cluster_data['delivery']['fqdn']
      end
    end

    context 'is NOT speficied and host' do
      before do
        node.default['delivery-cluster']['chef-server']['fqdn'] = nil
        node.default['delivery-cluster']['delivery']['fqdn'] = nil
      end

      context 'does exist' do
        it 'should return chef-server component host' do
          expect(described_class.component_fqdn(node, 'chef-server')).to eq cluster_data['chef-server']['host']
        end

        it 'should return delivery component host' do
          expect(described_class.component_fqdn(node, 'delivery')).to eq cluster_data['delivery']['host']
        end
      end

      context 'does NOT exist' do
        before do
          node.default['delivery-cluster']['chef-server']['host'] = nil
          node.default['delivery-cluster']['delivery']['host'] = nil
        end

        it 'should return chef-server component ip_address' do
          expect(described_class.component_fqdn(node, 'chef-server')).to eq '10.1.1.1'
        end

        it 'should return delivery component ip_address' do
          expect(described_class.component_fqdn(node, 'delivery')).to eq '10.1.1.2'
        end
      end
    end
  end
end
