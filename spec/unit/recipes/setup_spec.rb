#
# Cookbook Name:: delivery-cluster
# Spec:: setup_spec
#
# Author:: Ian Henry (<ihenry@chef.io>)
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

describe 'delivery-cluster::setup' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:activate_supermarket).and_return(true)
  end

  describe '#vagrant driver' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.set['delivery-cluster']            = cluster_data
        node.set['delivery-cluster']['driver']  = 'vagrant'
        node.set['delivery-cluster']['vagrant'] = vagrant_data
      end
    end

    before do
      DeliveryCluster::Helpers.instance_variable_set :@provisioning, nil
      chef_run.converge(described_recipe)
    end

    context 'always' do
      includes = %w( _settings setup_chef_server setup_delivery)
      includes.each do |recipename|
        it "includes #{recipename} recipe" do
          expect(chef_run).to include_recipe("delivery-cluster::#{recipename}")
        end
      end
    end

    context 'build-nodes without specs' do
      before do
        chef_run.node.set['delivery-cluster']['builders']['count'] = '99'
        chef_run.converge(described_recipe)
      end

      it 'converges successfully by rendering the attributes' do
        expect { chef_run }.to_not raise_error(RuntimeError)
        expect(chef_run.node['delivery-cluster']['builders']['99']).to eq(
          'hostname' => 'build-node-chefspec-99'
        )
      end
    end

    context 'when supermarket is enabled' do
      it 'includes supermarket recipe' do
        expect(chef_run).to include_recipe('delivery-cluster::setup_supermarket')
      end
    end

    context 'when supermarket is disabled' do
      before do
        chef_run.node.set['delivery-cluster']['supermarket'] = nil
        chef_run.converge(described_recipe)
      end
      it 'does not includes supermarket recipe' do
        expect(chef_run).to_not include_recipe('delivery-cluster::setup_supermarket')
      end
    end
  end

  describe '#aws driver' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.set['delivery-cluster']            = cluster_data
        node.set['delivery-cluster']['driver']  = 'aws'
        node.set['delivery-cluster']['aws']     = aws_data
      end
    end

    context 'always' do
      before do
        DeliveryCluster::Helpers.instance_variable_set :@provisioning, nil
        chef_run.converge(described_recipe)
      end

      includes = %w( _settings setup_chef_server setup_delivery)

      includes.each do |recipename|
        it "includes #{recipename} recipe" do
          expect(chef_run).to include_recipe("delivery-cluster::#{recipename}")
        end
      end
    end
  end

  describe '#ssh driver' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.set['delivery-cluster']            = cluster_data
        node.set['delivery-cluster']['driver']  = 'ssh'
        node.set['delivery-cluster']['ssh']     = ssh_data
      end
    end

    context 'always' do
      before do
        DeliveryCluster::Helpers.instance_variable_set :@provisioning, nil
        chef_run.converge(described_recipe)
      end

      includes = %w( _settings setup_chef_server setup_delivery)

      includes.each do |recipename|
        it "includes #{recipename} recipe" do
          expect(chef_run).to include_recipe("delivery-cluster::#{recipename}")
        end
      end
    end
  end
end
