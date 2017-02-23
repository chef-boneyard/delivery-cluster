#
# Cookbook Name:: delivery-cluster
# Spec:: helpers_delivery_spec
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

require 'chef/run_context'
require 'chef/event_dispatch/dispatcher'
require 'spec_helper'

describe DeliveryCluster::Helpers::Delivery do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }

  let(:extra_delivery_attributes) do
    {
      'passed-something' => %w(super cool),
      'a-custom-attribute' => 'carambola',
      'port-for-something' => 1234,
    }
  end
  before do
    node.default['delivery-cluster'] = cluster_data
    allow(FileUtils).to receive(:touch).and_return(true)
    allow(Chef::Node).to receive(:load).and_return(Chef::Node.new)
    allow(Chef::ServerAPI).to receive(:new).and_return(rest)
    allow_any_instance_of(Chef::ServerAPI).to receive(:get)
      .with('nodes/delivery-server-chefspec')
      .and_return(delivery_node)
  end

  it 'return the delivery hostname for a machine resource' do
    expect(described_class.delivery_server_hostname(node)).to eq 'delivery-server-chefspec'
  end

  it 'return the delivery dr hostname for a machine resource' do
    expect(described_class.delivery_server_dr_hostname(node)).to eq 'delivery-server-chefspec-disaster_recovery'
  end

  it 'return the delivery fqdn' do
    expect(described_class.delivery_server_fqdn(node)).to eq 'delivery-server.chef.io'
  end

  it 'return the just the delivery attributes without a remote artifact url' do
    attributes = described_class.delivery_server_attributes(node)
    expect(attributes['delivery-cluster']['delivery']['version']).to eq 'latest'
    expect(attributes['delivery-cluster']['delivery']['artifact']).to eq nil
    expect(attributes['delivery-cluster']['delivery']['checksum']).to eq nil
    expect(attributes['delivery-cluster']['delivery']['chef_server']).to eq 'https://chef-server.chef.io/organizations/chefspec'
    expect(attributes['delivery-cluster']['delivery']['fqdn']).to eq 'delivery-server.chef.io'
  end

  it 'return the just the delivery attributes with ips when dr without a remote artifact url' do
    attributes = described_class.delivery_server_attributes(node)
    expect(attributes['delivery-cluster']['delivery']['version']).to eq 'latest'
    expect(attributes['delivery-cluster']['delivery']['artifact']).to eq nil
    expect(attributes['delivery-cluster']['delivery']['checksum']).to eq nil
    expect(attributes['delivery-cluster']['delivery']['chef_server']).to eq 'https://chef-server.chef.io/organizations/chefspec'
    expect(attributes['delivery-cluster']['delivery']['fqdn']).to eq 'delivery-server.chef.io'
    expect(attributes['delivery-cluster']['delivery']['ip']).to eq '10.1.1.2'
    expect(attributes['delivery-cluster']['delivery']['disaster_recovery']['ip']).to eq '10.1.1.6'
  end

  context 'when driver is NOT specified' do
    it 'raise a RuntimeError' do
      expect { described_class.delivery_ctl(node) }.to raise_error(RuntimeError)
    end
  end

  context 'when driver is specified' do
    before do
      node.default['delivery-cluster']['driver'] = 'ssh'
      node.default['delivery-cluster']['ssh'] = ssh_data
    end

    context 'and Delivery version' do
      context 'is > 0.2.52 or latest' do
        it 'return the delivery-ctl command to create an enterprise with --ssh-pub-key-file' do
          # Asserting for specific patterns
          enterprise_cmd = described_class.delivery_enterprise_cmd(node)
          expect(enterprise_cmd =~ /sudo -E delivery-ctl/).not_to be nil
          expect(enterprise_cmd =~ /create-enterprise chefspec/).not_to be nil
          expect(enterprise_cmd =~ /--ssh-pub-key-file=/).not_to be nil
          expect(enterprise_cmd =~ %r{\/etc\/delivery\/builder_key.pub}).not_to be nil
          expect(enterprise_cmd =~ %r{\/tmp\/chefspec.creds}).not_to be nil
        end
      end

      context 'is < 0.2.52' do
        before { node.default['delivery-cluster']['delivery']['version'] = '0.2.50' }

        it 'return the delivery-ctl command to create an enterprise WITHOUT --ssh-pub-key-file' do
          # Asserting for specific patterns
          enterprise_cmd = described_class.delivery_enterprise_cmd(node)
          expect(enterprise_cmd =~ /sudo -E delivery-ctl/).not_to be nil
          expect(enterprise_cmd =~ /create-enterprise chefspec/).not_to be nil
          expect(enterprise_cmd =~ /--ssh-pub-key-file=/).to be nil
          expect(enterprise_cmd =~ %r{\/etc\/delivery\/builder_key.pub}).to be nil
          expect(enterprise_cmd =~ %r{\/tmp\/chefspec.creds}).not_to be nil
        end
      end
    end

    context 'and the user is NOT root' do
      it 'return the delivery_ctl command with sudo' do
        expect(described_class.delivery_ctl(node)).to eq 'sudo -E delivery-ctl'
      end
    end

    context 'and the user is root' do
      before do
        node.default['delivery-cluster']['ssh']['ssh_username'] = 'root'
        DeliveryCluster::Helpers.instance_variable_set :@provisioning, nil
      end
      it 'return the delivery_ctl command without sudo' do
        expect(described_class.delivery_ctl(node)).to eq 'delivery-ctl'
      end
    end
  end

  context 'when delivery attributes are not set' do
    before { node.default['delivery-cluster']['delivery'] = nil }

    it 'raise an error' do
      expect { described_class.delivery_server_hostname(node) }.to raise_error(RuntimeError)
    end
  end

  context 'when extra delivery attributes are specified' do
    before { node.default['delivery-cluster']['delivery']['attributes'] = extra_delivery_attributes }

    it 'returns extra delivery attributes deep merged' do
      attr_rendered = described_class.delivery_server_attributes(node)
      expect(attr_rendered.key(%w(super cool))).to eq('passed-something')
      expect(attr_rendered.key('carambola')).to eq('a-custom-attribute')
      expect(attr_rendered.key(1234)).to eq('port-for-something')
    end
  end
end
