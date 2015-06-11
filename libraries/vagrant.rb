
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
require 'chef/provisioning/driver'
require 'chef/provisioning/vagrant_driver'

class Chef::Provisioning::VagrantDriver::Driver < Chef::Provisioning::Driver
  def create_vm_file(action_handler, vm_name, vm_file_path, machine_options)
    # Determine contents of vm file
    vm_file_content = "Vagrant.configure('2') do |outer_config|\n"
    vm_file_content << "  outer_config.vm.define #{vm_name.inspect} do |config|\n"
    merged_vagrant_options = { 'vm.hostname' => vm_name }
    if machine_options[:vagrant_options]
      merged_vagrant_options = Cheffish::MergedConfig.new(machine_options[:vagrant_options], merged_vagrant_options)
    end
    merged_vagrant_options.each_pair do |key, value|
      if key == 'vm.network'
        vm_file_content << "    config.#{key}(" + value + ")\n"
      else
        vm_file_content << "    config.#{key} = #{value.inspect}\n"
      end
    end
    vm_file_content << machine_options[:vagrant_config] if machine_options[:vagrant_config]
    vm_file_content << "  end\nend\n"

    # Set up vagrant file
    Chef::Provisioning.inline_resource(action_handler) do
      file vm_file_path do
        content vm_file_content
        action :create
      end
    end
  end
end

module DeliveryCluster
  module Provisioning
    # Vagrant class for vb Provisioning Driver
    #
    # Specify all the methods a Provisioning Driver should implement
    # @author Ian Henry <ihenry@chef.io>
    class Vagrant <DeliveryCluster::Provisioning::Base
      attr_accessor :node
      attr_accessor :prefix
      attr_accessor :vm_box
      attr_accessor :image_url
      attr_accessor :vm_hostname
      attr_accessor :auth_methods
      attr_accessor :network
      attr_accessor :vm_mem
      attr_accessor :vm_cpus
      attr_accessor :port
      attr_accessor :auth_methods
      attr_accessor :bootstrap_proxy
      attr_accessor :chef_config

      # Create a new Provisioning Driver Abstraction
      #
      # @param node [Chef::Node]
      def initialize(node)
        require 'chef/provisioning/vagrant_driver'

        fail "Attributes not implemented (node['delivery-cluster'][#{driver}])" unless node['delivery-cluster'][driver]
        @node            = node
        @prefix          = 'sudo '
        @vm_box          = @node['delivery-cluster'][driver]['vm_box'] if @node['delivery-cluster'][driver]['vm_box']
        @image_url       = @node['delivery-cluster'][driver]['image_url'] if @node['delivery-cluster'][driver]['image_url']
        @vm_hostname     = @node['delivery-cluster'][driver]['vm_hostname'] if @node['delivery-cluster'][driver]['vm_hostname']
        @synced_folder   = @node['delivery-cluster'][driver]['synced_folder'] if @node['delivery-cluster'][driver]['synced_folder']
        @network         = @node['delivery-cluster'][driver]['network'] if @node['delivery-cluster'][driver]['network']
        @vm_mem          = @node['delivery-cluster'][driver]['vm_memory'] if @node['delivery-cluster'][driver]['vm_memory']
        @vm_cpus         = @node['delivery-cluster'][driver]['vm_cpus'] if @node['delivery-cluster'][driver]['vm_cpus']
        @auth_methods    = @node['delivery-cluster'][driver]['auth_methods'] if @node['delivery-cluster'][driver]['auth_methods']
        @port            = @node['delivery-cluster'][driver]['ssh_port'] if @node['delivery-cluster'][driver]['ssh_port']
        @prefix          = @node['delivery-cluster'][driver]['prefix'] if @node['delivery-cluster'][driver]['prefix']
        @key_file        = @node['delivery-cluster'][driver]['key_file'] if @node['delivery-cluster'][driver]['key_file']
        @bootstrap_proxy = @node['delivery-cluster'][driver]['bootstrap_proxy'] if @node['delivery-cluster'][driver]['bootstrap_proxy']
        @chef_config     = @node['delivery-cluster'][driver]['chef_config'] if @node['delivery-cluster'][driver]['chef_config']
        fail 'You should not specify both key_file and password.' if @password && @key_file
      end

      # Return the machine options to use.
      #
      # @return [Hash] the machine_options for the specific driver
      def machine_options
        {
          convergence_options: {
            bootstrap_proxy: @bootstrap_proxy,
            chef_config: @chef_config
          },
          vagrant_options: {
            'vm.box' => @vm_box,
            'vm.hostname' => @vm_hostname,
          },
          vagrant_config: @vagrant_config,
          transport_options: {
            ssh_options: {
              port: @port,
              auth_methods: @auth_methods
            },
            options: {
              prefix: @prefix
            }
          }
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
        def specific_machine_options(component, _count = nil)
          return [] unless @node['delivery-cluster'][component]
          options = []
          options << { vagrant_options: { 'vm.hostname' => @node['delivery-cluster'][component]['vm_hostname'] } } if @node['delivery-cluster'][component]['vm_hostname']
          options << { vagrant_options: { 'vm.box' => @node['delivery-cluster'][component]['vm_box'] } } if @node['delivery-cluster'][component]['vm_box']
          options << { vagrant_options: { 'vm.box_url' => @node['delivery-cluster'][component]['image_url'] } } if @node['delivery-cluster'][component]['image_url']
          options << { vagrant_options: { 'vm.network' => @node['delivery-cluster'][component]['network'] } } if @node['delivery-cluster'][component]['network']
          options << { vagrant_config:<<-ENDCONFIG
          config.vm.provider :virtualbox do |v|
            v.customize ["modifyvm", :id,'--memory', #{@node['delivery-cluster'][component]['vm_memory']}]
            v.customize ["modifyvm", :id, '--cpus', #{@node['delivery-cluster'][component]['vm_cpus']}]
          end
          ENDCONFIG
                     }
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
          node['ipaddress']
        end
      end
    end
  end
