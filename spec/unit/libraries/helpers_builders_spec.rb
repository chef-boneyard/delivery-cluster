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
  let(:chefdk_version) { '0.6.2-1.el6' }
  let(:extra_builders_attributes) do
    {
      'runit' => { 'prefer_local_yum' => true },
      'custom_behavior' => 'super-cool',
      'chef_ingredient' => 'custom-custom-custom',
    }
  end
  let(:delivery_actifact) do
    {
      'version' => '0.3.0',
      'artifact' => 'http://my.delivery-cli.pkg',
      'checksum' => '123456789ABCDEF',
    }
  end
  let(:mock_global_trusted_certs) do
    {
      'Proxy Cert' => 'my_proxy.cer',
      'Corp Cert' => 'corporate.crt',
      'Open Cert' => 'other_open.crt',
    }
  end
  let(:result_internal_plus_global_certs) do
    {
      'Chef Server Cert' => '/etc/chef/trusted_certs/chef-server.chef.io.crt',
      'Delivery Server Cert' => '/etc/chef/trusted_certs/delivery-server.chef.io.crt',
      'Supermarket Server' => '/etc/chef/trusted_certs/supermarket-server.chef.io.crt',
      'Proxy Cert' => '/etc/chef/trusted_certs/my_proxy.cer',
      'Corp Cert' => '/etc/chef/trusted_certs/corporate.crt',
      'Open Cert' => '/etc/chef/trusted_certs/other_open.crt',
    }
  end

  before do
    node.default['delivery-cluster'] = cluster_data
    allow(FileUtils).to receive(:touch).and_return(true)
    allow(Chef::Node).to receive(:load).and_return(Chef::Node.new)
    allow(Chef::ServerAPI).to receive(:new).and_return(rest)
  end

  context 'when the builder hostname' do
    context 'is NOT set' do
      it 'returns the builders hostname for a machine resource' do
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

      it 'returns the specific builders hostname for a machine resource' do
        expect(described_class.delivery_builder_hostname(node, '1')).to eq 'my-cool-build-node-1'
        expect(described_class.delivery_builder_hostname(node, '2')).to eq 'my-awesome-build-node-2'
        expect(described_class.delivery_builder_hostname(node, '3')).to eq 'my-great-build-node-3'
      end
    end
  end

  context 'when the builder specs' do
    context 'does NOT exist' do
      it 'not complain whether we pass an index as a number or as a string' do
        expect(described_class.delivery_builder_hostname(node, 1)).to eq 'build-node-chefspec-1'
        expect(described_class.delivery_builder_hostname(node, '1')).to eq 'build-node-chefspec-1'
      end
    end

    context 'does exist' do
      before do
        node.default['delivery-cluster']['builders']['count'] = 3
        node.default['delivery-cluster']['builders']['1'] = { 'hostname' => 'my-awesome-build-node-1' }
        node.default['delivery-cluster']['builders']['2'] = { 'hostname' => 'my-awesome-build-node-2' }
        node.default['delivery-cluster']['builders']['3'] = { 'hostname' => 'my-awesome-build-node-3' }
      end

      it 'not complain whether we pass an index as a number or as a string' do
        expect(described_class.delivery_builder_hostname(node, 1)).to eq 'my-awesome-build-node-1'
        expect(described_class.delivery_builder_hostname(node, '1')).to eq 'my-awesome-build-node-1'
      end

      it 'returns the right hostname for the build-nodes' do
        1.upto(node['delivery-cluster']['builders']['count']) do |i|
          expect(described_class.delivery_builder_hostname(node, i)).to eq "my-awesome-build-node-#{i}"
        end
      end
    end
  end

  context 'when the builder private key' do
    context 'does NOT exist' do
      it 'raise an error' do
        expect { described_class.builder_private_key(node) }.to raise_error(Errno::ENOENT)
      end
    end

    context 'does exist' do
      before { allow(File).to receive(:read).and_return(true) }

      it 'returns the key' do
        expect(described_class.builder_private_key(node)).to eq true
      end
    end
  end

  context 'when an additional_run_list' do
    context 'is NOT specified' do
      it 'returns the right run_list for the builders' do
        expect(described_class.builder_run_list(node)).to eq %w( recipe[push-jobs] recipe[delivery_build] )
      end
    end

    context 'is specified' do
      before do
        node.default['delivery-cluster']['builders']['additional_run_list'] = ['recipe[awesome-cookbook]']
        DeliveryCluster::Helpers::Builders.instance_variable_set :@builder_run_list, nil
      end

      it 'returns the right run_list for the builders plus the additional run_list' do
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

  describe '#trusted_certs_attributes' do
    before do
      allow_any_instance_of(Chef::ServerAPI).to receive(:get)
        .with('nodes/delivery-server-chefspec')
        .and_return(delivery_node)
    end

    it 'always return the Delivery and Chef Server Cert' do
      expect(described_class.builders_attributes(node)).to eq(
        'delivery_build' => {
          'trusted_certs' => {
            'Chef Server Cert' => '/etc/chef/trusted_certs/chef-server.chef.io.crt',
            'Delivery Server Cert' => '/etc/chef/trusted_certs/delivery-server.chef.io.crt',
          },
        }
      )
    end

    context 'when Supermarket Server is enabled' do
      before do
        allow(DeliveryCluster::Helpers::Supermarket).to receive(:supermarket_enabled?)
          .and_return(true)
        allow_any_instance_of(Chef::ServerAPI).to receive(:get)
          .with('nodes/supermarket-server-chefspec')
          .and_return(supermarket_node)
      end

      it 'returns also the Supermarket server cert' do
        expect(described_class.builders_attributes(node)).to eq(
          'delivery_build' => {
            'trusted_certs' => {
              'Chef Server Cert' => '/etc/chef/trusted_certs/chef-server.chef.io.crt',
              'Delivery Server Cert' => '/etc/chef/trusted_certs/delivery-server.chef.io.crt',
              'Supermarket Server' => '/etc/chef/trusted_certs/supermarket-server.chef.io.crt',
            },
          }
        )
      end

      context 'and the user specify additional certificates' do
        before do
          node.default['delivery-cluster']['trusted_certs'] = mock_global_trusted_certs
        end

        it 'returns all of the certificates' do
          expect(described_class.builders_attributes(node)).to eq(
            'delivery_build' => {
              'trusted_certs' => result_internal_plus_global_certs,
            }
          )
        end
      end
    end
  end

  describe '#builders_files' do
    before do
      allow(DeliveryCluster::Helpers).to receive(:cluster_data_dir).and_return('/chefspec')
      allow(Dir).to receive(:glob).and_return([])
    end

    it 'returns at least the encrypted_data_bag_secret file' do
      expect(described_class.builders_files(node)).to eq(
        '/etc/chef/encrypted_data_bag_secret' => '/chefspec/encrypted_data_bag_secret'
      )
    end

    context 'when there are some certificates to upload' do
      let(:mock_cert_file) do
        [
          '/chefspec/trusted_certs/cool.crt',
          '/chefspec/trusted_certs/super.crt',
          '/chefspec/trusted_certs/cocina.crt',
        ]
      end
      before { allow(Dir).to receive(:glob).and_return(mock_cert_file) }

      it 'returns encrypted_data_bag_secret plus certificate files' do
        expect(described_class.builders_files(node)).to eq(
          '/etc/chef/encrypted_data_bag_secret' => '/chefspec/encrypted_data_bag_secret',
          '/etc/chef/trusted_certs/cool.crt' => '/chefspec/trusted_certs/cool.crt',
          '/etc/chef/trusted_certs/super.crt' => '/chefspec/trusted_certs/super.crt',
          '/etc/chef/trusted_certs/cocina.crt' => '/chefspec/trusted_certs/cocina.crt'
        )
      end
    end
  end

  describe '#builders_attributes' do
    before do
      # Mocking this method since it is being tested already
      allow(described_class).to receive(:trusted_certs_attributes)
        .and_return({})
    end

    it 'returns an empty Hash if there are no attributes' do
      expect(described_class.builders_attributes(node)).to eq({})
    end

    context 'when delivery-cli attributes are set' do
      before do
        node.default['delivery-cluster']['builders']['delivery-cli'] = delivery_actifact
      end

      it 'returns the delivery-cli attributes' do
        expect(described_class.builders_attributes(node)).to eq(
          'delivery_build' => {
            'delivery-cli' => delivery_actifact,
          }
        )
      end

      context 'and the chefdk_version is set as well' do
        before do
          node.default['delivery-cluster']['builders']['chefdk_version'] = chefdk_version
        end

        it 'returns both the chefdk_version and delivery-cli attributes' do
          expect(described_class.builders_attributes(node)).to eq(
            'delivery_build' => {
              'delivery-cli' => delivery_actifact,
              'chefdk_version' => chefdk_version,
            }
          )
        end

        context 'plus a bunch of certificates' do
          before do
            allow(described_class).to receive(:trusted_certs_attributes)
              .and_return(
                'delivery_build' => {
                  'trusted_certs' => result_internal_plus_global_certs,
                })
          end

          it 'returns lots of attributes deep merged' do
            expect(described_class.builders_attributes(node)).to eq(
              'delivery_build' => {
                'delivery-cli' => delivery_actifact,
                'chefdk_version' => chefdk_version,
                'trusted_certs' => result_internal_plus_global_certs,
              }
            )
          end

          context 'plus extra attributes that the user specified' do
            before do
              node.default['delivery-cluster']['builders']['attributes'] = extra_builders_attributes
            end

            it 'returns lots of attributes deep merged plus the extra attributes' do
              expect(described_class.builders_attributes(node)).to eq(
                extra_builders_attributes.merge(
                  'delivery_build' => {
                    'delivery-cli' => delivery_actifact,
                    'chefdk_version' => chefdk_version,
                    'trusted_certs' => result_internal_plus_global_certs,
                  }
                )
              )
            end
          end
        end
      end
    end
  end
end
