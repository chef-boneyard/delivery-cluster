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
  chef_ingredient plugin do
    action :install
    notifies :reconfigure, "chef_ingredient[chef-server]", :immediately
  end

  ingredient_config plugin do
    notifies :reconfigure, "chef_ingredient[#{plugin}]", :immediately
  end
end
