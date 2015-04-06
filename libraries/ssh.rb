#
# Cookbook Name:: delivery-cluster
# Library:: ssh
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

module DeliveryCluster
  module Provisioning

    # Ssh class for SsH Provisioning Driver
    #
    # Specify all the methods a Provisioning Driver should implement
    # @author Salim Afiune <afiune@chef.io>
    class Ssh < DeliveryCluster::Provisioning::Base

      require 'chef/provisioning/ssh_driver'

      attr_accessor :node
      attr_accessor :key_file
      attr_accessor :ssh_username

      # Create a new Provisioning Driver Abstraction
      #
      # @param node [Chef::Node]
      def initialize(node)
        raise "[#{driver}] Attributes not implemented (node['delivery-cluster'][#{driver}])" unless node['delivery-cluster'][driver]
        @node          = node
        @ssh_username  = @node['delivery-cluster'][driver]['ssh_username'] if @node['delivery-cluster'][driver]['ssh_username']
        @key_file      = @node['delivery-cluster'][driver]['key_file'] if @node['delivery-cluster'][driver]['key_file']
      end

      # Return the machine options to use.
      #
      # @return [Hash] the machine_options for the specific driver
      def machine_options
        {
          transport_options: {
            username: @ssh_username,
            ssh_options: {
              user: @ssh_username,
              keys: [@key_file]
            },
            options: {
              prefix: "sudo "
            }
          }
        }
      end

      # Create a array of machine_options specifics to a component
      #
      # @param component [String] component name
      # @param count [Integer] component number
      # @return [Array] specific machine_options for the specific component
      def specific_machine_options(component, count = nil)
        return [] unless @node['delivery-cluster'][component]
        options = []
        if count
          options << { transport_options: { ip_address: @node['delivery-cluster'][component][count.to_s]['ip'] } } if @node['delivery-cluster'][component][count.to_s]['ip']
        else
          options << { transport_options: { ip_address: @node['delivery-cluster'][component]['ip'] } } if @node['delivery-cluster'][component]['ip']
        end
        # Specify more specific machine_options to add
      end

      # Return the Provisioning Driver Name.
      #
      # @return [String] the provisioning driver name
      def driver
        'ssh'
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
