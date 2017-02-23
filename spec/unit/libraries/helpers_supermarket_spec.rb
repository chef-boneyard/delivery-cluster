#
# Cookbook Name:: delivery-cluster
# Spec:: helpers_supermarket_spec
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

describe DeliveryCluster::Helpers::Supermarket do
  let(:node) { Chef::Node.new }
  let(:mock_supermarket_server_attributes) do
    {
      'supermarket' => {
        'fqdn' => 'supermarket-server.chef.io',
      },
    }
  end
  let(:mock_supermarket_json) do
    <<-EOF.gsub(/^ {6}/, '')
      {
        "name": "supermarket",
        "uid": "768fd17555298930830180eedc8ff6ca45736a8c392bbcbe866c804efb25262d",
        "secret": "154b8a364e60deb3d83771df9159639362cd59a60661a63f9b126e794bd95daa",
        "redirect_uri": "https://33.33.33.17/auth/chef_oauth2/callback"
      }
    EOF
  end

  before do
    node.default['delivery-cluster'] = cluster_data
    allow(FileUtils).to receive(:touch).and_return(true)
    allow(Chef::Node).to receive(:load).and_return(Chef::Node.new)
    allow(Chef::ServerAPI).to receive(:new).and_return(rest)
    allow_any_instance_of(Chef::ServerAPI).to receive(:get)
      .with('nodes/supermarket-server-chefspec')
      .and_return(supermarket_node)
  end

  it 'returns the supermarket hostname for a machine resource' do
    expect(described_class.supermarket_server_hostname(node)).to eq 'supermarket-server-chefspec'
  end

  it 'returns the supermarket fqdn' do
    expect(described_class.supermarket_server_fqdn(node)).to eq 'supermarket-server.chef.io'
  end

  it 'returns the PATH of the supermarket lock file' do
    expect(described_class.supermarket_lock_file(node)).to eq File.join(Chef::Config.chef_repo_path, '.chef', 'delivery-cluster-data-chefspec', 'supermarket')
  end

  context 'when supermarket' do
    context 'is NOT enabled' do
      before { allow(File).to receive(:exist?).and_return(false) }

      it 'say that supermarket component is NOT enabled' do
        expect(described_class.supermarket_enabled?(node)).to eq false
      end

      it 'returns NO attributes' do
        expect(described_class.supermarket_server_attributes(node)).to eq({})
      end
    end

    context 'is enabled' do
      before { allow(File).to receive(:exist?).and_return(true) }

      it 'say that supermarket component is enabled' do
        expect(described_class.supermarket_enabled?(node)).to eq true
      end

      it 'returns the supermarket attributes' do
        expect(described_class.supermarket_server_attributes(node)).to eq('chef-server-12' => mock_supermarket_server_attributes)
      end
    end
  end

  context 'when supermarket.json' do
    context 'does NOT exist' do
      it 'raise and error' do
        expect { described_class.get_supermarket_attribute(node, 'uid') }.to raise_error(Errno::ENOENT)
      end
    end

    context 'does exist' do
      before do
        allow(File).to receive(:read).and_return(mock_supermarket_json)
        allow(File).to receive(:exist?).and_return(true)
      end

      it 'returns the uid attribute' do
        expect(described_class.get_supermarket_attribute(node, 'uid')).to eq '768fd17555298930830180eedc8ff6ca45736a8c392bbcbe866c804efb25262d'
      end

      it 'returns the secret attribute' do
        expect(described_class.get_supermarket_attribute(node, 'secret')).to eq '154b8a364e60deb3d83771df9159639362cd59a60661a63f9b126e794bd95daa'
      end

      it 'returns the supermarket server configuration' do
        expect(described_class.supermarket_config(node)).to eq(
          'supermarket-config' => {
            'fqdn' => 'supermarket-server.chef.io',
            'host' => 'supermarket-server.chef.io',
            'chef_server_url' => 'https://chef-server.chef.io',
            'chef_oauth2_app_id' => '768fd17555298930830180eedc8ff6ca45736a8c392bbcbe866c804efb25262d',
            'chef_oauth2_secret' => '154b8a364e60deb3d83771df9159639362cd59a60661a63f9b126e794bd95daa',
            'chef_oauth2_verify_ssl' => false,
          }
        )
      end
    end
  end

  it 'activate supermarket by creating the lock file' do
    expect(described_class.activate_supermarket(node)).to eq true
  end

  context 'when supermarket attributes are not set' do
    before { node.default['delivery-cluster']['supermarket'] = nil }

    it 'raise an error' do
      expect { described_class.supermarket_server_hostname(node) }.to raise_error(RuntimeError)
    end
  end
end
