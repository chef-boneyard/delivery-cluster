#
# Cookbook Name:: chef-server-12
# Spec:: default_spec
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

describe "chef-server-12::default WITHOUT delivery setup" do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      platform: 'redhat',
      version: '6.3',
      log_level: :error
    )
    runner.node.set['chef-server-12']['delivery_setup'] = false
    Chef::Config.force_logger true
    runner.converge('recipe[chef-server-12::default]')
  end

  it 'install chef-server package' do
    expect(chef_run).to install_package('chef-server')
  end

  it 'creates chef-server.rb file' do
    expect(chef_run).to create_template('/etc/opscode/chef-server.rb')
  end

  it 'creates /etc/opscode directory' do
    expect(chef_run).to create_directory('/etc/opscode')
  end
end

describe "chef-server-12::default WITH delivery setup" do
  before do
    stub_command("chef-server-ctl org-list | grep -w chef_delivery").and_return(false)
    stub_command("chef-server-ctl user-list | grep -w delivery").and_return(false)
  end

  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      platform: 'redhat',
      version: '6.3',
      log_level: :error
    )
    runner.node.set['chef-server-12']['delivery_setup'] = true
    Chef::Config.force_logger true
    runner.converge('recipe[chef-server-12::default]')
  end

  it 'create delivery organization' do
    expect(chef_run).to run_execute("Create #{chef_run.node['chef-server-12']['delivery']['organization']} Organization")
  end

  it 'create delivery user' do
    expect(chef_run).to run_execute("Create #{chef_run.node['chef-server-12']['delivery']['user']} User")
  end

  it 'install chef-server package' do
    expect(chef_run).to install_package('chef-server')
  end

  it 'creates chef-server.rb file' do
    expect(chef_run).to create_template('/etc/opscode/chef-server.rb')
  end

  it 'creates /etc/opscode directory' do
    expect(chef_run).to create_directory('/etc/opscode')
  end
end
