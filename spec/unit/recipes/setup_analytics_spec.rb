#
# Cookbook Name:: delivery-cluster
# Spec:: setup_analytics_spec
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

describe 'delivery-cluster::setup_analytics' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['delivery-cluster'] = cluster_data
    end.converge(described_recipe)
  end

  before do
    allow_any_instance_of(Chef::Recipe).to receive(:activate_analytics).and_return(true)
    allow_any_instance_of(Chef::Recipe).to receive(:cluster_data_dir).and_return('/tmp')
  end

  it 'includes _settings recipe' do
    expect(chef_run).to include_recipe('delivery-cluster::_settings')
  end

  it 'converge analytics machine' do
    expect(chef_run).to converge_machine('analytics-server-chefspec')
  end

  it 'converge chef-server machine' do
    expect(chef_run).to converge_machine('chef-server-chefspec')
  end

  %w( actions-source.json webui_priv.pem ).each do |analytics_file|
    it "download #{analytics_file}" do
      expect(chef_run).to download_machine_file("/etc/opscode-analytics/#{analytics_file}")
        .with_machine('chef-server-chefspec')
    end
  end

  it 'download analytics-server-cert' do
    expect(chef_run).to download_machine_file('analytics-server-cert')
      .with_machine('analytics-server-chefspec')
  end

  it 'add analytics to the rendered knife.rb' do
    expect(chef_run).to create_template('/tmp/knife.rb')
  end
end
