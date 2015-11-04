#
# Cookbook Name:: delivery-cluster
# Spec:: setup_supermarket_spec
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

describe 'delivery-cluster::setup_supermarket' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['delivery-cluster'] = cluster_data
    end.converge(described_recipe)
  end

  before do
    allow_any_instance_of(Chef::Recipe).to receive(:activate_supermarket).and_return(true)
    allow_any_instance_of(Chef::Recipe).to receive(:cluster_data_dir).and_return('/tmp')
  end

  it 'includes _settings recipe' do
    expect(chef_run).to include_recipe('delivery-cluster::_settings')
  end

  it 'converge supermarket machine' do
    expect(chef_run).to converge_machine('supermarket-server-chefspec')
  end

  it 'activates supermarket through a ruby_block resource' do
    expect(chef_run).to run_ruby_block('Activate Supermarket')
  end

  it 'converge chef-server machine' do
    expect(chef_run).to converge_machine('chef-server-chefspec')
  end

  it 'download the file supermarket.json' do
    expect(chef_run).to download_machine_file('/etc/opscode/oc-id-applications/supermarket.json')
      .with_machine('chef-server-chefspec')
  end

  it 'download supermarket-server-cert' do
    expect(chef_run).to download_machine_file('supermarket-server-cert')
      .with_machine('supermarket-server-chefspec')
  end

  it 'add supermarket to the rendered knife.rb' do
    expect(chef_run).to create_template('/tmp/knife.rb')
  end
end
