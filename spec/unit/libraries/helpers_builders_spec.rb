#
# Cookbook Name:: delivery-cluster
# Spec:: helpers_builders_spec
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

describe DeliveryCluster::Helpers::Builders do
  let(:node) { Chef::Node.new }
  before do
    node.default['delivery-cluster'] = cluster_data
    allow(FileUtils).to receive(:touch).and_return(true)
    allow(Chef::Node).to receive(:load).and_return(Chef::Node.new)
    allow(Chef::REST).to receive(:new).and_return(rest)
  end

  context 'when the builder hostname' do
    context 'is NOT set' do
      it 'return the builders hostname for a machine resource' do
        1.upto(cluster_data['builders']['count'].to_i) do |index|
          expect(described_class.delivery_builder_hostname(node, index)).to eq "build-node-chefspec-#{index}"
        end
      end
    end
    context 'is set' do
      before do
        node.default['delivery-cluster']['builders']['1']['hostname'] = 'my-cool-build-node-1'
        node.default['delivery-cluster']['builders']['2']['hostname'] = 'my-awesome-build-node-2'
        node.default['delivery-cluster']['builders']['3']['hostname'] = 'my-great-build-node-3'
      end

      it 'return the specific builders hostname for a machine resource' do
        expect(described_class.delivery_builder_hostname(node, '1')).to eq 'my-cool-build-node-1'
        expect(described_class.delivery_builder_hostname(node, '2')).to eq 'my-awesome-build-node-2'
        expect(described_class.delivery_builder_hostname(node, '3')).to eq 'my-great-build-node-3'
      end
    end
  end

  it 'not complain whether we pass an index as a number or as a string' do
    expect(described_class.delivery_builder_hostname(node, 1)).to eq 'build-node-chefspec-1'
    expect(described_class.delivery_builder_hostname(node, '1')).to eq 'build-node-chefspec-1'
  end

  context 'when the builder private key' do
    context 'does NOT exist' do
      it 'raise an error' do
        expect { described_class.builder_private_key(node) }.to raise_error(Errno::ENOENT)
      end
    end

    context 'does exist' do
      before { allow(File).to receive(:read).and_return(true) }

      it 'return the key' do
        expect(described_class.builder_private_key(node)).to eq true
      end
    end
  end

  context 'when an additional_run_list' do
    context 'is NOT specified' do
      it 'return the right run_list for the builders' do
        expect(described_class.builder_run_list(node)).to eq %w( recipe[push-jobs] recipe[delivery_build] )
      end
    end

    context 'is specified' do
      before do
        node.default['delivery-cluster']['builders']['additional_run_list'] = ['recipe[awesome-cookbook]']
        DeliveryCluster::Helpers::Builders.instance_variable_set :@builder_run_list, nil
      end

      it 'return the right run_list for the builders plus the additional run_list' do
        expect(described_class.builder_run_list(node)).to eq %w( recipe[push-jobs] recipe[delivery_build] recipe[awesome-cookbook] )
      end
    end
  end

  context 'when builders attributes are not set' do
    before { node.default['delivery-cluster']['builders'] = nil }

    it 'raise an error' do
      expect { described_class.delivery_builder_hostname(node, '1') }.to raise_error(RuntimeError)
    end
  end
end
