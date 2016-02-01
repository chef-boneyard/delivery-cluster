#
# Cookbook Name:: delivery-cluster
# Spec:: delivery_spec
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

describe 'delivery-cluster::delivery' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['delivery-cluster'] = cluster_data
    end.converge(described_recipe)
  end

  before do
    allow(File).to receive(:exist?).and_return(true)
  end

  it 'upgrades delivery through chef-ingredient' do
    expect(chef_run).to upgrade_chef_ingredient('delivery')
  end

  it 'creates /etc/delivery directory' do
    expect(chef_run).to create_directory('/etc/delivery')
  end

  it 'creates /etc/delivery/delivery.rb configuration file' do
    expect(chef_run).to render_file('/etc/delivery/delivery.rb')
      .with_content { |content|
        expect(content).to include('delivery_fqdn')
        expect(content).to include("insights['enable'] = false")
      }
  end
end
