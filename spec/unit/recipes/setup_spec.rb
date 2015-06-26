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
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['delivery-cluster'] = cluster_data
    end
  end

  context 'always' do
    before do
      chef_run.converge(described_recipe)
    end

    includes = %w( _settings setup_chef_server setup_delivery)

    includes.each do |recipename|
      it "includes #{recipename} recipe" do
        expect(chef_run).to include_recipe("delivery-cluster::#{recipename}")
      end
    end
  end

  context 'lots of build nodes without configuration' do
    before do
      chef_run.node.set['delivery-cluster']['builders']['count'] = '99'
    end

    it 'raise error' do
      expect { chef_run.converge(described_recipe) }.to raise_error(RuntimeError)
    end
  end
end
