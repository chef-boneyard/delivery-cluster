#
# Cookbook Name:: delivery-cluster
# Spec:: helpers_insights_spec
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

describe DeliveryCluster::Helpers::Insights do
  let(:node) { Chef::Node.new }
  let(:mock_insights_config) do
    {
      'insights' => {
        'rabbitmq' => {
          'exchange' => 'chefspec-insights',
          'user' => 'chefspec-insights',
          'password' => 'chefspec-chefrocks',
          'vip' => 'delivery-server.mock.io',
        },
      },
    }
  end

  before do
    node.default['delivery-cluster'] = cluster_data
    allow(FileUtils).to receive(:touch).and_return(true)
    allow(Chef::Node).to receive(:load).and_return(Chef::Node.new)
    allow(Chef::ServerAPI).to receive(:new).and_return(rest)
    allow(DeliveryCluster::Helpers::Delivery).to receive(:delivery_server_fqdn).with(node).and_return('delivery-server.mock.io')
  end

  it 'return the PATH of the insights lock file' do
    expect(described_class.insights_lock_file(node)).to eq File.join(Chef::Config.chef_repo_path, '.chef', 'delivery-cluster-data-chefspec', 'insights')
  end

  context 'when insights' do
    context 'is NOT enabled' do
      before { allow(File).to receive(:exist?).and_return(false) }

      it 'say that insights component is NOT enabled' do
        expect(described_class.insights_enabled?(node)).to eq false
      end

      it 'return NO attributes' do
        expect(described_class.insights_config(node)).to eq({})
      end
    end

    context 'is enabled' do
      before { allow(File).to receive(:exist?).and_return(true) }

      context 'and Analytics is enabled at the same time' do
        before do
          allow(DeliveryCluster::Helpers::Insights).to receive(:analytics_enabled?).and_return(true)
        end

        it 'throws an error saying you cant activate both' do
          expect { described_class.activate_insights(node) }.to raise_error(RuntimeError)
        end
      end

      context do
        it 'says that insights component is enabled' do
          expect(described_class.insights_enabled?(node)).to eq true
        end

        it 'returns the insights config' do
          expect(described_class.insights_config(node)).to eq('chef-server-12' => mock_insights_config)
        end
      end
    end
  end

  it 'activates insights by creating the lock file' do
    expect(described_class.activate_insights(node)).to eq true
  end
end
