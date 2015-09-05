#
# Cookbook Name:: delivery-cluster
# Spec:: pkg_repo_management_spec
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

describe 'delivery-cluster::pkg_repo_management' do
  context 'debian systems' do
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(
        platform: 'ubuntu',
        version: '14.04',
        log_level: :error
      )
      runner.converge(described_recipe)
    end

    it 'include apt cookbook' do
      expect(chef_run).to include_recipe 'apt'
    end

    it 'NOT include yum cookbook' do
      expect(chef_run).to_not include_recipe 'yum'
    end
  end

  context 'rhel systems' do
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(
        platform: 'redhat',
        version: '6.5',
        log_level: :error
      )
      runner.converge(described_recipe)
    end

    it 'include yum cookbook' do
      expect(chef_run).to include_recipe 'yum'
    end

    it 'NOT include apt cookbook' do
      expect(chef_run).to_not include_recipe 'apt'
    end

    it 'clean cache at compile time' do
      expect(chef_run).to run_execute('yum clean all').at_compile_time
    end
  end

  context 'windows systems' do
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(
        platform: 'windows',
        version: '2008R2',
        log_level: :error
      )
      runner.converge(described_recipe)
    end

    before do
      # Mocking Windows Environment Variables that `omnibus` cookbook use
      ENV['SYSTEMDRIVE'] = 'C:'
      ENV['USERPROFILE'] = 'C:/Users'
    end

    it 'NOT include yum cookbook' do
      expect(chef_run).to_not include_recipe 'yum'
    end

    it 'NOT include apt cookbook' do
      expect(chef_run).to_not include_recipe 'apt'
    end

    it 'write log' do
      expect(chef_run).to write_log 'delivery-cluster-pkg-repo-update-not-handled'
    end
  end
end
