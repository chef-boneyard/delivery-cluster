#
# Cookbook Name:: chef-server-12
# Libraries:: default
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

def install_plugin(plugin)
  plugin_attrs = node['chef-server-12'][plugin]
  plugin_config = plugin_attrs['config'] if plugin_attrs

  chef_ingredient plugin do
    accept_license node['chef-server-12']['accept_license']
    platform_version_compatibility_mode true
    channel node['chef-server-12']['package_channel'].to_sym
    config plugin_config if plugin_config
    action :install
    notifies :reconfigure, "chef_ingredient[chef-server]", :immediately
  end

  ingredient_config plugin do
    notifies :reconfigure, "chef_ingredient[#{plugin}]", :immediately
  end
end
