
# Cookbook Name:: delivery-cluster
# Library:: vagrant
#
# Author:: Ian Henry (<ihenry@chef.io>)
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

require_relative '_base'

module DeliveryCluster
  module Provisioning
    #
    # Vagrant class for vb Provisioning Driver
    #
    # Specify all the methods a Provisioning Driver should implement
    # @author Ian Henry <ihenry@chef.io>
    class Vagrant < DeliveryCluster::Provisioning::Base
      attr_accessor :node
      attr_accessor :prefix
      attr_accessor :use_private_ip_for_ssh

      # Create a new Provisioning Driver Abstraction
      #
      # @param node [Chef::Node]
      def initialize(node)
        require 'chef/provisioning/vagrant_driver'

        DeliveryCluster::Helpers.check_attribute?(node['delivery-cluster'][driver], "node['delivery-cluster']['#{driver}']")
        @node         = node
        @prefix       = 'sudo '
        @driver_hash  = @node['delivery-cluster'][driver]
        @use_private_ip_for_ssh = false

        @driver_hash.each do |attr, value|
          singleton_class.class_eval { attr_accessor attr }
          instance_variable_set("@#{attr}", value)
        end

        raise 'You should not specify both key_file and password.' if @password && @key_file
      end

      # Return the machine options to use.
      #
      # @return [Hash] the machine_options for the specific driver
      def machine_options
        {
          convergence_options: {
            bootstrap_proxy: @bootstrap_proxy,
            chef_config: @chef_config,
            chef_version: @chef_version,
            install_sh_path: @install_sh_path,
          },
          vagrant_options: {
            'vm.box' => @vm_box,
            'vm.box_url' => @image_url,
            'vm.hostname' => @vm_hostname,
          },
          vagrant_config: @vagrant_config, # memory and cpu, required
          transport_options: {
            options: {
              prefix: @prefix,
            },
          },
          use_private_ip_for_ssh: @use_private_ip_for_ssh,
        }
      end

      # Create a array of machine_options specifics to a component
      # We also inject optional configuration parameters into this
      # hash instead of forcing all parameters. Specifically
      #
      # 'vm.network' and 'vm.box_url'
      #
      # @param component [String] component name
      # @param count [Integer] component number
      # @return [Array] specific machine_options for the specific component
      def specific_machine_options(component, count = nil)
        return [] unless @node['delivery-cluster'][component]
        options = []
        if count
          DeliveryCluster::Helpers.check_attribute?(@node['delivery-cluster'][component][count.to_s], "node['delivery-cluster']['#{driver}']['#{count}']")
          options << { vagrant_options: { 'vm.hostname' => @node['delivery-cluster'][component][count.to_s]['vm_hostname'] } } if @node['delivery-cluster'][component][count.to_s]['vm_hostname']
          options << { vagrant_options: { 'vm.box' => @node['delivery-cluster'][component][count.to_s]['vm_box'] } } if @node['delivery-cluster'][component][count.to_s]['vm_box']
          options << { vagrant_options: { 'vm.box_url' => @node['delivery-cluster'][component][count.to_s]['image_url'] } } if @node['delivery-cluster'][component][count.to_s]['image_url']
          options << { vagrant_options: { 'vm.network' => @node['delivery-cluster'][component][count.to_s]['network'] } } if @node['delivery-cluster'][component][count.to_s]['network']
          options << { vagrant_config: <<-ENDCONFIG.gsub(/^ {10}/, '')
            config.vm.network(#{@node['delivery-cluster'][component][count.to_s]['network']})
            config.vm.provider :virtualbox do |v|
              v.customize ["modifyvm", :id,'--memory', #{@node['delivery-cluster'][component][count.to_s]['vm_memory']}]
              v.customize ["modifyvm", :id, '--cpus', #{@node['delivery-cluster'][component][count.to_s]['vm_cpus']}]
            end
            ENDCONFIG
          }
        else
          options << { vagrant_options: { 'vm.hostname' => @node['delivery-cluster'][component]['vm_hostname'] } } if @node['delivery-cluster'][component]['vm_hostname']
          options << { vagrant_options: { 'vm.box' => @node['delivery-cluster'][component]['vm_box'] } } if @node['delivery-cluster'][component]['vm_box']
          options << { vagrant_options: { 'vm.box_url' => @node['delivery-cluster'][component]['image_url'] } } if @node['delivery-cluster'][component]['image_url']
          options << { vagrant_options: { 'vm.network' => @node['delivery-cluster'][component]['network'] } } if @node['delivery-cluster'][component]['network']
          options << { vagrant_config: <<-ENDCONFIG.gsub(/^ {10}/, '')
            config.vm.provider :virtualbox do |v|
              v.customize ["modifyvm", :id,'--memory', #{@node['delivery-cluster'][component]['vm_memory']}]
              v.customize ["modifyvm", :id, '--cpus', #{@node['delivery-cluster'][component]['vm_cpus']}]
            end
            ENDCONFIG
          }
        end
        options
      end

      # Return the Provisioning Driver Name.
      #
      # @return [String] the provisioning driver name
      def driver
        'vagrant'
      end

      # Return the ipaddress from the machine.
      #
      # @param node [Chef::Node]
      # @return [String] an ipaddress
      def ipaddress(node)
        if @use_private_ip_for_ssh
          node[:network][:interfaces][:eth1][:addresses].detect { |_k, v| v[:family] == 'inet' }.first
        else
          node['ipaddress']
        end
      end

      # Return the username of the Provisioning Driver.
      #
      # @return [String] the username
      def username
        'vagrant'
      end
    end
  end
end
