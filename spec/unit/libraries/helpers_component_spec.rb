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
  before do
    node.default['delivery-cluster'] = cluster_data
    allow(Chef::Node).to receive(:load).and_return(Chef::Node.new)
    allow(Chef::ServerAPI).to receive(:new).and_return(rest)
    allow_any_instance_of(Chef::ServerAPI).to receive(:get)
      .with('nodes/chef-server-chefspec')
      .and_return(chef_node)
    allow_any_instance_of(Chef::ServerAPI).to receive(:get)
      .with('nodes/delivery-server-chefspec')
      .and_return(delivery_node)
    allow_any_instance_of(Chef::ServerAPI).to receive(:get)
      .with('nodes/supermarket-server-chefspec')
      .and_return(supermarket_node)
    allow_any_instance_of(Chef::ServerAPI).to receive(:get)
      .with('nodes/analytics-server-chefspec')
      .and_return(analytics_node)
    allow_any_instance_of(Chef::ServerAPI).to receive(:get)
      .with('nodes/splunk-server-chefspec')
      .and_return(splunk_node)
    allow_any_instance_of(Chef::ServerAPI).to receive(:get)
      .with('nodes/delivery-server-chefspec-disaster_recovery')
      .and_return(delivery_dr_node)
  end

  context 'when fqdn' do
    context 'is speficied' do
      it 'return chef-server component fqdn' do
        expect(described_class.component_fqdn(node, 'chef-server')).to eq cluster_data['chef-server']['fqdn']
      end

      it 'return delivery component fqdn' do
        expect(described_class.component_fqdn(node, 'delivery')).to eq cluster_data['delivery']['fqdn']
      end

      it 'return supermarket component fqdn' do
        expect(described_class.component_fqdn(node, 'supermarket')).to eq cluster_data['supermarket']['fqdn']
      end

      it 'return analytics component fqdn' do
        expect(described_class.component_fqdn(node, 'analytics')).to eq cluster_data['analytics']['fqdn']
      end

      it 'return splunk component fqdn' do
        expect(described_class.component_fqdn(node, 'splunk')).to eq cluster_data['splunk']['fqdn']
      end
    end

    context 'is NOT speficied and host' do
      before do
        node.default['delivery-cluster']['chef-server']['fqdn'] = nil
        node.default['delivery-cluster']['delivery']['fqdn']    = nil
        node.default['delivery-cluster']['supermarket']['fqdn'] = nil
        node.default['delivery-cluster']['analytics']['fqdn']   = nil
        node.default['delivery-cluster']['splunk']['fqdn']      = nil
      end

      context 'does exist' do
        it 'return chef-server component host' do
          expect(described_class.component_fqdn(node, 'chef-server')).to eq cluster_data['chef-server']['host']
        end

        it 'return delivery component host' do
          expect(described_class.component_fqdn(node, 'delivery')).to eq cluster_data['delivery']['host']
        end

        it 'return supermarket component host' do
          expect(described_class.component_fqdn(node, 'supermarket')).to eq cluster_data['supermarket']['host']
        end

        it 'return analytics component host' do
          expect(described_class.component_fqdn(node, 'analytics')).to eq cluster_data['analytics']['host']
        end

        it 'return splunk component host' do
          expect(described_class.component_fqdn(node, 'splunk')).to eq cluster_data['splunk']['host']
        end
      end

      context 'does NOT exist' do
        before do
          node.default['delivery-cluster']['chef-server']['host'] = nil
          node.default['delivery-cluster']['delivery']['host']    = nil
          node.default['delivery-cluster']['delivery']['disaster_recovery']['host'] = nil
          node.default['delivery-cluster']['supermarket']['host'] = nil
          node.default['delivery-cluster']['analytics']['host']   = nil
          node.default['delivery-cluster']['splunk']['host']      = nil
          node.default['delivery-cluster']['driver'] = 'ssh'
          node.default['delivery-cluster']['ssh'] = ssh_data
        end

        it 'return chef-server component ip_address' do
          expect(described_class.component_fqdn(node, 'chef-server')).to eq '10.1.1.1'
        end

        it 'return delivery component ip_address' do
          expect(described_class.component_fqdn(node, 'delivery')).to eq '10.1.1.2'
        end

        it 'return supermarket component ip_address' do
          expect(described_class.component_fqdn(node, 'supermarket')).to eq '10.1.1.3'
        end

        it 'return analytics component ip_address' do
          expect(described_class.component_fqdn(node, 'analytics')).to eq '10.1.1.4'
        end

        it 'return splunk component ip_address' do
          expect(described_class.component_fqdn(node, 'splunk')).to eq '10.1.1.5'
        end
      end
    end
  end

  context 'when `hostname` attribute' do
    context 'is NOT configured' do
      %w( delivery supermarket analytics splunk ).each do |component|
        it "generate a hostname for #{component}" do
          expect(described_class.component_hostname(node, component)).to eq "#{component}-server-chefspec"
        end
      end

      it 'generate a hostname for chef-server' do
        expect(described_class.component_hostname(node, 'chef-server')).to eq 'chef-server-chefspec'
      end

      it 'generate a hostname for delivery dr server' do
        expect(described_class.component_hostname(node, 'delivery', 'disaster_recovery')).to eq 'delivery-server-chefspec-disaster_recovery'
      end
    end

    context 'is configured' do
      before do
        node.default['delivery-cluster']['chef-server']['hostname'] = 'my-cool-hostname.chef-server.com'
        node.default['delivery-cluster']['delivery']['hostname']    = 'my-cool-hostname.delivery.com'
        node.default['delivery-cluster']['supermarket']['hostname'] = 'my-cool-hostname.supermarket.com'
        node.default['delivery-cluster']['analytics']['hostname']   = 'my-cool-hostname.analytics.com'
        node.default['delivery-cluster']['splunk']['hostname']      = 'my-cool-hostname.splunk.com'
      end

      %w( chef-server delivery supermarket analytics splunk ).each do |component|
        it "return our cool-#{component} hostname" do
          expect(described_class.component_hostname(node, component)).to eq "my-cool-hostname.#{component}.com"
        end
      end
    end
  end

  it 'return the hostname for multiple machines' do
    1.upto(cluster_data['builders']['count'].to_i) do |index|
      expect(described_class.component_hostname(node, 'builders', index.to_s)).to eq "build-node-chefspec-#{index}"
    end
  end

  context 'when the component attributes are not set' do
    before do
      node.default['delivery-cluster']['chef-server']  = nil
      node.default['delivery-cluster']['delivery']     = nil
      node.default['delivery-cluster']['supermarket']  = nil
      node.default['delivery-cluster']['analytics']    = nil
      node.default['delivery-cluster']['splunk']       = nil
      node.default['delivery-cluster']['builders']     = nil
    end

    %w( chef-server delivery supermarket analytics splunk builders ).each do |component|
      it "raise an error for #{component}" do
        expect { described_class.component_hostname(node, component) }.to raise_error(RuntimeError)
      end
    end

    it 'raise an error when you try to access a multiple_component_hostname' do
      expect { described_class.component_hostname(node, 'machines', '1') }.to raise_error(RuntimeError)
    end
  end

  context 'when ip' do
    before do
      node.default['delivery-cluster']['driver'] = 'ssh'
      node.default['delivery-cluster']['ssh'] = ssh_data
    end

    context 'is speficied' do
      it 'return chef-server component ip' do
        expect(described_class.component_ip(node, 'chef-server')).to eq cluster_data['chef-server']['ip']
      end

      it 'return delivery component ip' do
        expect(described_class.component_ip(node, 'delivery')).to eq cluster_data['delivery']['ip']
      end

      it 'return delivery component dr ip' do
        expect(described_class.component_ip(node, 'delivery', 'disaster_recovery')).to eq cluster_data['delivery']['disaster_recovery']['ip']
      end

      it 'return supermarket component ip' do
        expect(described_class.component_ip(node, 'supermarket')).to eq cluster_data['supermarket']['ip']
      end

      it 'return analytics component ip' do
        expect(described_class.component_ip(node, 'analytics')).to eq cluster_data['analytics']['ip']
      end

      it 'return splunk component ip' do
        expect(described_class.component_ip(node, 'splunk')).to eq cluster_data['splunk']['ip']
      end
    end

    context 'is not speficied' do
      before do
        node.default['delivery-cluster']['chef-server']['ip'] = nil
        node.default['delivery-cluster']['delivery']['ip']    = nil
        node.default['delivery-cluster']['supermarket']['ip'] = nil
        node.default['delivery-cluster']['analytics']['ip']   = nil
        node.default['delivery-cluster']['splunk']['ip']      = nil
      end
      it 'return chef-server component ip' do
        expect(described_class.component_ip(node, 'chef-server')).to eq '10.1.1.1'
      end

      it 'return delivery component ip' do
        expect(described_class.component_ip(node, 'delivery')).to eq '10.1.1.2'
      end

      it 'return delivery component dr ip' do
        expect(described_class.component_ip(node, 'delivery', 'disaster_recovery')).to eq '10.1.1.6'
      end

      it 'return supermarket component ip' do
        expect(described_class.component_ip(node, 'supermarket')).to eq '10.1.1.3'
      end

      it 'return analytics component ip' do
        expect(described_class.component_ip(node, 'analytics')).to eq '10.1.1.4'
      end

      it 'return splunk component ip' do
        expect(described_class.component_ip(node, 'splunk')).to eq '10.1.1.5'
      end
    end
  end
end
