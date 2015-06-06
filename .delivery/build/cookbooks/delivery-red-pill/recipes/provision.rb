#
# Cookbook Name:: delivery-red-pill
# Recipe:: provision
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
include_recipe 'delivery-truck::provision'

if node['delivery']['change']['pipeline'] == 'master' && node['delivery']['change']['stage'] == 'acceptance'
  matrix = node['delivery-red-pill']['acceptance']['matrix']

  delivery_in_parallel do
    for vector in matrix do
      delivery_duplicate_change_on_pipeline vector do
        auto_approve true
      end
    end
  end

  delivery_change_db node['delivery']['change']['change_id']

  delivery_in_parallel do
    for vector in matrix do
      delivery_wait_for_stage "Wait for stage: #{node['delivery']['change']['stage']} on pipeline: #{vector}" do
        change_id lazy { node.run_state['delivery']['change']['data']['spawned_changes'][vector] }
        stage 'build'
      end
    end
  end
elsif node['delivery']['change']['pipeline'] != 'master'
  include_recipe "delivery-red-pill::_include_build_cb_recipe"
end
