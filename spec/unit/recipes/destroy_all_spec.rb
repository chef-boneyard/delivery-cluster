#
# Cookbook Name:: delivery-cluster
# Spec:: destroy_all_spec
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

describe 'delivery-cluster::destroy_all' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['delivery-cluster'] = cluster_data
    end
  end

  context 'always' do
    before do
      allow(DeliveryCluster::Helpers).to receive(:is_cluster_data_dir_link?).and_return(true)
      chef_run.converge(described_recipe)
    end

    includes = %w(
      _settings destroy_builders destroy_analytics destroy_supermarket
      destroy_splunk destroy_delivery destroy_delivery_dr destroy_chef_server
      destroy_cluster_data
    )

    includes.each do |recipename|
      it "includes #{recipename} recipe" do
        expect(chef_run).to include_recipe("delivery-cluster::#{recipename}")
      end
    end
  end
end
