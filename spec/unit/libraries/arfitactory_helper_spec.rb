#
# Cookbook Name:: delivery-cluster
# Spec:: artifactory_helper_spec
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
require 'chef/node'
require 'chef/run_context'
require 'chef/event_dispatch/dispatcher'

# Storing the state of the Chef VPN
vpn_state = validate_vpn

describe 'Library#artifactory_helper' do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:mock_delivery_artifact_for_v_0_3_165) do
    {
      'name' => 'delivery_0.3.165-1_amd64.deb',
      'version' => '0.3.165',
      'checksum' => 'ab225f7dd3a64d211b768626c5665d2013cd708921d44355e57339ececb59bd1',
      'uri' => 'http://artifactory.chef.co/omnibus-current-local/com/getchef/delivery/0.3.165/ubuntu/14.04/delivery_0.3.165-1_amd64.deb'
    }
  end

  before do
    node.default['delivery-cluster'] = cluster_data
    allow_any_instance_of(Chef::Node).to receive(:run_context).and_return(run_context)
    allow_any_instance_of(Chef::Resource::ChefGem).to receive(:run_action).and_return(true)
  end

  describe '#validate_vpn' do
    if vpn_state
      it 'returns a ::Net::HTTP object' do
        expect(validate_vpn).to be_a(Net::HTTPFound)
      end
    else
      it 'exit with a fatal error' do
        expect(validate_vpn).to eql(false)
      end
    end
  end

  describe '#get_delivery_artifact' do
    if vpn_state
      context 'works only with Chef VPN' do
        it 'returns artifact using the defaults' do
          artifact = get_delivery_artifact(node)
          expect(artifact['checksum']).to be_a(String)
          expect(artifact['version']).to be_a(String)
          expect(artifact['name']).to be_a(String)
          expect(artifact['uri']).to be_a(String)
        end

        it 'returns artifact of an specific version' do
          expect(get_delivery_artifact(node, '0.3.165'))
            .to eql(mock_delivery_artifact_for_v_0_3_165)
        end
      end
    else
      context 'does NOT works without Chef VPN' do
        it 'raise error' do
          expect { get_delivery_artifact(node) }.to raise_error(SystemExit)
        end
      end
    end
  end

  describe '#supported_platforms_format' do
    context 'ubuntu platforms' do
      it 'returns a Hash' do
        supported = supported_platforms_format('ubuntu', '12.04')
        expect(supported).to eql(
          'platform' => 'ubuntu',
          'version' => '12.04'
        )
      end

      it 'exit with a fatal error' do
        expect { supported_platforms_format('ubuntu', '12.02') }
          .to raise_error(SystemExit)
      end
    end

    context 'centos & redhat platforms' do
      it 'returns a Hash' do
        supported = supported_platforms_format('centos', '6.1')
        expect(supported).to eql(
          'platform' => 'el',
          'version' => '6'
        )
        supported = supported_platforms_format('redhat', '6.6')
        expect(supported).to eql(
          'platform' => 'el',
          'version' => '6'
        )
      end

      it 'exit with a fatal error' do
        expect { supported_platforms_format('centos', '5') }
          .to raise_error(SystemExit)
      end
    end

    context 'other platforms' do
      it 'exit with a fatal error' do
        expect { supported_platforms_format('windows', '2008R2') }
          .to raise_error(SystemExit)
      end
    end
  end
end
