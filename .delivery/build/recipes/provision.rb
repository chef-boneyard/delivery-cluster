#
# Cookbook Name:: build
# Recipe:: provision
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# By including this recipe we trigger a matrix of acceptance envs specified
# in the node attribute node['delivery-red-pill']['acceptance']['matrix']
include_recipe "delivery-red-pill::provision"

if node['delivery']['change']['pipeline'] != 'master'
  ruby_block "Get Services" do
    block do
      list_services = Mixlib::ShellOut.new("rake info:list_core_services",
                                           :cwd => node['delivery']['workspace']['repo'])

      list_services.run_command

      if list_services.stdout
        node.run_state['delivery'] ||= {}
        node.run_state['delivery']['stage'] ||= {}
        node.run_state['delivery']['stage']['data'] ||= {}
        node.run_state['delivery']['stage']['data']['servers'] ||= {}

        previous_line = nil
        list_services.stdout.each_line do |line|
          if previous_line =~ /^delivery-server\S+:$/
            ipaddress = line.match(/^  ipaddress: (\S+)$/)[1]
            node.run_state['delivery']['stage']['data']['servers']['delivery_server'] = ipaddress
          elsif previous_line =~ /^build-node\S+:/
            ipaddress = line.match(/^  ipaddress: (\S+)$/)[1]
            node.run_state['delivery']['stage']['data']['servers']['build_nodes'] ||= []
            node.run_state['delivery']['stage']['data']['servers']['build_nodes'] << ipaddress
          elsif line =~ /^chef_server_url.*$/
            ipaddress = URI(line.match(/^chef_server_url\s+'(\S+)'$/)[1]).host
            node.run_state['delivery']['stage']['data']['servers']['chef_server'] = ipaddress
          end
          previous_line = line
        end
      end
    end
  end

  delivery_stage_db
end
