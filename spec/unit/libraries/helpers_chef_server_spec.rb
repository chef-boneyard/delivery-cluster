#
# Cookbook Name:: delivery-cluster
# Spec:: helpers_chef_spec_spec
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
  let(:mock_chef_server_attributes) do
    {
        'delivery' => { 'organization' => 'chefspec' },
        'api_fqdn' => 'chef-server.chef.io',
        'store_keys_databag' => false,
        'plugin' => {
          'opscode-reporting' => true
        }
    }
  end
  let(:mock_analytics_server_attributes) do
    {
      'analytics' => {
        'fqdn' => 'analytics-server.chef.io'
      }
    }
  end
  let(:mock_supermarket_server_attributes) do
    {
      'supermarket' => {
        'fqdn' => 'supermarket-server.chef.io'
      }
    }
  end

  before do
    node.default['delivery-cluster'] = cluster_data
    node.default['delivery-cluster']['chef-server']['enable-reporting'] = true
    allow(Chef::Node).to receive(:load).and_return(Chef::Node.new)
    allow(Chef::REST).to receive(:new).and_return(rest)
    allow_any_instance_of(Chef::REST).to receive(:get_rest)
      .with("nodes/supermarket-server-chefspec")
      .and_return(supermarket_node)
    allow_any_instance_of(Chef::REST).to receive(:get_rest)
      .with("nodes/analytics-server-chefspec")
      .and_return(analytics_node)
  end

  it 'should return chef-server hostname for a machine resource' do
    expect(described_class.chef_server_hostname(node)).to eq 'chef-server-chefspec'
  end

  it 'should return chef-server fqdn' do
    expect(described_class.chef_server_fqdn(node)).to eq 'chef-server.chef.io'
  end

  it 'should return chef-server url' do
    expect(described_class.chef_server_url(node)).to eq 'https://chef-server.chef.io/organizations/chefspec'
  end

  it 'should return the chef-server configuration for a machine resource' do
    expect(described_class.chef_server_config(node)).to eq(
        chef_server_url: 'https://chef-server.chef.io/organizations/chefspec',
        options: {
          client_name: 'delivery',
          signing_key_filename: File.join(Chef::Config.chef_repo_path, '.chef', 'delivery-cluster-data-chefspec', 'delivery.pem')
        }
      )
  end

  context 'when there is neither supermarket server nor analytics server' do
    it 'should return just the chef-server attributes' do
      expect(described_class.chef_server_attributes(node)).to eq('chef-server-12' => mock_chef_server_attributes)
    end
  end

  context 'when there is a supermarket server' do
    before do
      allow(DeliveryCluster::Helpers).to receive(:supermarket_enabled?).and_return(true)
    end

    it 'should return the chef-server attributes plus supermarket attributes' do
      expect(described_class.chef_server_attributes(node)).to eq(
          'chef-server-12' => mock_chef_server_attributes.merge(mock_supermarket_server_attributes)
        )
    end
  end

  context 'when there is a analytics server' do
    before do
      allow(DeliveryCluster::Helpers).to receive(:analytics_enabled?).and_return(true)
    end

    it 'should return the chef-server attributes plus analytics attributes' do
      expect(described_class.chef_server_attributes(node)).to eq(
          'chef-server-12' => mock_chef_server_attributes.merge(mock_analytics_server_attributes)
        )
    end

    context 'AND a supermarket server (both)' do
      before do
        allow(DeliveryCluster::Helpers).to receive(:supermarket_enabled?).and_return(true)
      end

      it 'should return the chef-server attributes plus supermarket attributes plust analytics attributes' do
        expect(described_class.chef_server_attributes(node)).to eq(
            'chef-server-12' => mock_chef_server_attributes
              .merge(mock_supermarket_server_attributes)
              .merge(mock_analytics_server_attributes)
          )
      end
    end
  end
end
