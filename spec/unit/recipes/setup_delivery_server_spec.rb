#
# Cookbook Name:: delivery-cluster
# Spec:: setup_delivery_server_spec
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

describe 'delivery-cluster::setup_delivery_server' do
  let(:insights_enabled) { true }
  let(:insights_attributes) do
    {
      'rabbitmq' => {
        'vip' => 'delivery-server.chef.io',
        'vhost' => '/insights',
        'exchange' => 'chefspec-insights',
        'port' => '5672',
        'user' => 'chefspec-insights',
        'password' => 'chefspec-chefrocks',
      },
    }
  end
  let(:chef_server_attributes) do
    {
      'chef-server-12' => {
        'accept_license' => cluster_data['accept_license'],
        'delivery' => {
          'organization' => 'chefspec',
          'password' => 'SECRET',
        },
        'api_fqdn' => 'chef-server.chef.io',
        'store_keys_databag' => false,
        'plugin' => { 'reporting' => true },
        'data_collector' => {
          'root_url' => nil,
          'token' => nil,
        },
        'insights' => insights_attributes,
      },
    }
  end
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['delivery-cluster'] = cluster_data
      node.set['delivery-cluster']['delivery']['insights']['enable'] = insights_enabled
      node.set['delivery-cluster']['chef-server']['delivery_password'] = 'SECRET'
    end.converge(described_recipe)
  end

  before do
    allow_any_instance_of(Chef::Resource).to receive(:cluster_data_dir)
      .and_return('/repo/delivery-cluster-dir')
    allow_any_instance_of(Chef::Resource).to receive(:delivery_server_fqdn)
      .and_return(cluster_data['delivery']['fqdn'])
    allow(Chef::Node).to receive(:load).and_return(Chef::Node.new)
    allow(Chef::ServerAPI).to receive(:new).and_return(rest)
    allow_any_instance_of(Chef::ServerAPI).to receive(:get)
      .with('nodes/chef-server-chefspec')
      .and_return(chef_node)
    allow_any_instance_of(Chef::ServerAPI).to receive(:get)
      .with('nodes/delivery-server-chefspec')
      .and_return(delivery_node)
    allow(Chef::Config).to receive(:chef_repo_path).and_return('/repo/delivery-cluster-dir')
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?)
      .with('/repo/delivery-cluster-dir/.chef/delivery-cluster-data-chefspec/insights')
      .and_return(true)
    DeliveryCluster::Helpers::ChefServer.instance_variable_set :@chef_server_delivery_password, nil
  end

  it 'includes _settings recipe' do
    expect(chef_run).to include_recipe('delivery-cluster::_settings')
  end

  it 'converge delivery machine' do
    expect(chef_run).to converge_machine('delivery-server-chefspec')
      .with_files(
        '/etc/delivery/delivery.pem' => '/repo/delivery-cluster-dir/delivery.pem',
        '/etc/delivery/builder_key' => '/repo/delivery-cluster-dir/builder_key',
        '/etc/delivery/builder_key.pub' => '/repo/delivery-cluster-dir/builder_key.pub'
      )
  end

  it 'download the credentials chefspec.creds' do
    expect(chef_run).to download_machine_file('/tmp/chefspec.creds')
      .with_machine('delivery-server-chefspec')
  end

  it 'download delivery-server-cert' do
    expect(chef_run).to download_machine_file('delivery-server-cert')
      .with_machine('delivery-server-chefspec')
  end

  it 'create an enterprise' do
    expect(chef_run).to run_machine_execute('Creating Enterprise')
      .with_machine('delivery-server-chefspec')
  end

  context 'when insights is enabled' do
    let(:insights_enabled) { true }

    it 'updates chef-server with delivery address' do
      expect(chef_run).to converge_machine('chef-server-chefspec')
        .with_attributes(chef_server_attributes)
    end
  end

  context 'when insights is disabled' do
    let(:insights_enabled) { false }

    it 'updates chef-server with delivery address' do
      expect(chef_run).not_to converge_machine('chef-server-chefspec')
    end
  end
end
