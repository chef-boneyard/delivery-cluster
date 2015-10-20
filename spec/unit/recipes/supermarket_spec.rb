#
# Cookbook Name:: delivery-cluster
# Spec:: supermarket_spec
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

describe 'delivery-cluster::supermarket' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new do |node|
      node.set['delivery-cluster'] = cluster_data
    end.converge(described_recipe)
  end

  before do
    allow(JSON).to receive(:pretty_generate).and_return('config')
    stub_command('grep Fauxhai /etc/hosts').and_return(true)
  end

  it 'adds supermarket ingredient config' do
    expect(chef_run).to add_ingredient_config('supermarket')
  end

  it 'installs and reconfigures supermarket ingredient' do
    expect(chef_run).to install_chef_ingredient('supermarket')
    expect(chef_run).to reconfigure_chef_ingredient('supermarket')
  end
end
