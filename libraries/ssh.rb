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

      # Create a new Provisioning Driver Abstraction
      #
      # @param node [Chef::Node]
      def initialize(node)
      end

      # Return the machine options to use.
      #
      # @return [Hash] the machine_options for the specific driver
      def machine_options
        {
          transport_options: {
            username: node['delivery-cluster']['ssh']['username'],
            ssh_options: {
              user: node['delivery-cluster']['ssh']['username'],
              keys: [node['delivery-cluster']['ssh']['key_file']]
            },
            options: {
              prefix: "sudo "
            }
          }
        }
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
      def ipaddress(node, use_private_ip_for_ssh = false)
        node['ipaddress']
      end

    end
  end
end
