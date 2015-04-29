#
# Cookbook Name:: chef-server-12
# Recipe:: analytics
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

if File.exist?('/etc/opscode/chef-server.rb')
  template "/etc/opscode/chef-server.rb" do
    owner "root"
    mode "0644"
    not_if 'grep analytics /etc/opscode/chef-server.rb'
    notifies :run, "execute[stop chef]", :immediately
    notifies :run, "execute[reconfigure chef]", :immediately
    notifies :run, "execute[restart chef]", :immediately
    notifies :run, "execute[reconfigure opscode-manage]", :immediately
  end if node['chef-server-12']['analytics']

  %W{
    restart
    stop
    reconfigure
  }.each do |cmd|
    execute "#{cmd} chef" do
      command "chef-server-ctl #{cmd}"
      action :nothing
    end
  end

  execute "reconfigure opscode-manage" do
    command "opscode-manage-ctl reconfigure"
    action :nothing
  end
end
