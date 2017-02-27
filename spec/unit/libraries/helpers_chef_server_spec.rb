#
# Cookbook Name:: delivery-cluster
# Spec:: helpers_chef_server_spec
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

describe DeliveryCluster::Helpers::ChefServer do
  let(:node) { Chef::Node.new }
  let(:chef_server_delivery_password) { 'SuperSecurePassword' }
  let(:extra_chef_server_attributes) do
    {
      'passed-something' => %w(super cool),
      'a-custom-attribute' => 'carambola',
      'port-for-something' => 1234,
    }
  end
  let(:mock_chef_server_attributes) do
    {
      'accept_license' => cluster_data['accept_license'],
      'delivery' => {
        'organization' => 'chefspec',
        'password' => chef_server_delivery_password,
      },
      'api_fqdn' => 'chef-server.chef.io',
      'store_keys_databag' => false,
      'plugin' => {
        'reporting' => true,
      },
      'data_collector' => {
        'root_url' => nil,
        'token' => nil,
      },
    }
  end
  let(:mock_analytics_server_attributes) do
    {
      'analytics' => {
        'fqdn' => 'analytics-server.chef.io',
      },
    }
  end
  let(:mock_supermarket_server_attributes) do
    {
      'supermarket' => {
        'fqdn' => 'supermarket-server.chef.io',
      },
    }
  end

  before do
    node.default['delivery-cluster'] = cluster_data
    node.default['delivery-cluster']['chef-server']['enable-reporting'] = true
    node.default['delivery-cluster']['chef-server']['data_collector'] = {}
    allow(Chef::Node).to receive(:load).and_return(Chef::Node.new)
    allow(Chef::ServerAPI).to receive(:new).and_return(rest)
    allow_any_instance_of(Chef::ServerAPI).to receive(:get)
      .with('nodes/supermarket-server-chefspec')
      .and_return(supermarket_node)
    allow_any_instance_of(Chef::ServerAPI).to receive(:get)
      .with('nodes/analytics-server-chefspec')
      .and_return(analytics_node)
  end

  it 'returns chef-server hostname for a machine resource' do
    expect(described_class.chef_server_hostname(node)).to eq 'chef-server-chefspec'
  end

  it 'returns chef-server fqdn' do
    expect(described_class.chef_server_fqdn(node)).to eq 'chef-server.chef.io'
  end

  it 'returns chef-server fqdn' do
    expect(described_class.chef_server_fqdn(node)).to eq 'chef-server.chef.io'
  end

  it 'returns a random delivery password' do
    random_password = described_class.chef_server_delivery_password(node)
    expect(described_class.chef_server_delivery_password(node)).to_not eq chef_server_delivery_password
    expect(described_class.chef_server_delivery_password(node)).to eq random_password
  end

  it 'return the chef-server configuration for a machine resource' do
    expect(described_class.chef_server_config(node)).to eq(
      chef_server_url: 'https://chef-server.chef.io/organizations/chefspec',
      options: {
        client_name: 'delivery',
        signing_key_filename: File.join(Chef::Config.chef_repo_path, '.chef', 'delivery-cluster-data-chefspec', 'delivery.pem'),
      }
    )
  end

  context 'with same delivery password' do
    # Mock the delivery passsword to test other attributes
    before do
      allow(DeliveryCluster::Helpers::ChefServer).to receive(:chef_server_delivery_password)
        .and_return(chef_server_delivery_password)
    end

    context 'when there is neither supermarket server nor analytics server' do
      it 'return just the chef-server attributes' do
        expect(described_class.chef_server_attributes(node)).to eq('chef-server-12' => mock_chef_server_attributes)
      end
    end

    context 'when there is a supermarket server' do
      before do
        allow(DeliveryCluster::Helpers::Supermarket).to receive(:supermarket_enabled?).and_return(true)
      end

      it 'return the chef-server attributes plus supermarket attributes' do
        expect(described_class.chef_server_attributes(node)).to eq(
          'chef-server-12' => mock_chef_server_attributes.merge(mock_supermarket_server_attributes)
        )
      end
    end

    context 'when there is a analytics server' do
      before do
        allow(DeliveryCluster::Helpers::Analytics).to receive(:analytics_enabled?).and_return(true)
      end

      it 'return the chef-server attributes plus analytics attributes' do
        expect(described_class.chef_server_attributes(node)).to eq(
          'chef-server-12' => mock_chef_server_attributes.merge(mock_analytics_server_attributes)
        )
      end

      context 'AND a supermarket server (both)' do
        before do
          allow(DeliveryCluster::Helpers::Supermarket).to receive(:supermarket_enabled?).and_return(true)
        end

        it 'return the chef-server attributes plus supermarket attributes plus analytics attributes' do
          expect(described_class.chef_server_attributes(node)).to eq(
            'chef-server-12' => mock_chef_server_attributes
              .merge(mock_supermarket_server_attributes)
              .merge(mock_analytics_server_attributes)
          )
        end

        context 'plus extra attributes that the user specified' do
          before do
            node.default['delivery-cluster']['chef-server']['attributes'] = extra_chef_server_attributes
          end

          it 'returns all of them plus the extra attributes' do
            expect(described_class.chef_server_attributes(node)).to eq(
              extra_chef_server_attributes.merge(
                'chef-server-12' => mock_chef_server_attributes
                  .merge(mock_supermarket_server_attributes)
                  .merge(mock_analytics_server_attributes)
              )
            )
          end
        end
      end
    end
  end

  context 'when chef-server attributes are not set' do
    before { node.default['delivery-cluster']['chef-server'] = nil }

    it 'raise an error' do
      expect { described_class.chef_server_hostname(node) }.to raise_error(RuntimeError)
    end
  end
end
