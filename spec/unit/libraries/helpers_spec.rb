#
# Cookbook Name:: delivery-cluster
# Spec:: helpers_spec
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

describe DeliveryCluster::Helpers do
  let(:node) { Chef::Node.new }

  before do
    node.default['delivery-cluster'] = cluster_data
    allow(DeliveryCluster::Helpers).to receive(:node).and_return(node)
  end

  context 'helper methods should let us test it' do
    it 'should return the cluster_id' do
      expect(described_class.delivery_cluster_id(node)).to eq 'chefspec'
    end
  end
end
