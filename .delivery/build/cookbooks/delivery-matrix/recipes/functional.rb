#
# Cookbook Name:: delivery-matrix
# Recipe:: functional
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

include_recipe 'delivery-truck::functional'

if node['delivery']['change']['pipeline'] == 'master' && node['delivery']['change']['stage'] == 'acceptance'
  delivery_change_db node['delivery']['change']['change_id'] do
    action :download
  end

  ## Monitor pipeline acceptance stages for completion.
  delivery_in_parallel do
    matrix = node['delivery-matrix']['acceptance']['matrix']
    ## If you do not use .ech here the lazy evals get all messed up and evaluate
    ## each iteration as if it was the last.
    matrix.each do |vector|
      delivery_wait_for_stage "Wait for #{node['delivery']['change']['stage']} case #{vector}" do
        change_id lazy { node.run_state['delivery']['change']['data']['spawned_changes']["#{vector}"] }
        stage node['delivery']['change']['stage']
      end
    end
  end
elsif node['delivery']['change']['pipeline'] != 'master'
  include_recipe "delivery-matrix::_include_build_cb_recipe"
end
