#
# Cookbook Name:: delivery-cluster
# Spec:: helpers_splunk_spec
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

describe DeliveryCluster::Helpers::Splunk do
  let(:node) { Chef::Node.new }
  before do
    node.default['delivery-cluster'] = cluster_data
    allow(FileUtils).to receive(:touch).and_return(true)
    allow(Chef::Node).to receive(:load).and_return(Chef::Node.new)
    allow(Chef::ServerAPI).to receive(:new).and_return(rest)
    allow_any_instance_of(Chef::ServerAPI).to receive(:get)
      .with('nodes/splunk-server-chefspec')
      .and_return(splunk_node)
  end

  it 'return the splunk hostname for a machine resource' do
    expect(described_class.splunk_server_hostname(node)).to eq 'splunk-server-chefspec'
  end

  it 'return the splunk fqdn' do
    expect(described_class.splunk_server_fqdn(node)).to eq 'splunk-server.chef.io'
  end

  it 'return the PATH of the splunk lock file' do
    expect(described_class.splunk_lock_file(node)).to eq File.join(Chef::Config.chef_repo_path, '.chef', 'delivery-cluster-data-chefspec', 'splunk')
  end

  context 'when splunk' do
    context 'is NOT enabled' do
      before { allow(File).to receive(:exist?).and_return(false) }

      it 'say that splunk component is NOT enabled' do
        expect(described_class.splunk_enabled?(node)).to eq false
      end
    end

    context 'is enabled' do
      before { allow(File).to receive(:exist?).and_return(true) }

      it 'say that splunk component is enabled' do
        expect(described_class.splunk_enabled?(node)).to eq true
      end
    end
  end

  it 'activate splunk by creating the lock file' do
    expect(described_class.activate_splunk(node)).to eq true
  end

  context 'when splunk attributes are not set' do
    before { node.default['delivery-cluster']['splunk'] = nil }

    it 'raise an error' do
      expect { described_class.splunk_server_hostname(node) }.to raise_error(RuntimeError)
    end
  end
end
