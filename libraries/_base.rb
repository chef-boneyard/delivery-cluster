#
# Cookbook Name:: delivery-cluster
# Library:: base
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

module DeliveryCluster
  module Provisioning

    # Base class for a Provisioning Abstraction.
    #
    # Specify all the methods a Provisioning Driver should implement
    # @author Salim Afiune <afiune@chef.io>
    class Base

      # Create a new Provisioning Driver Abstraction
      #
      # @param node [Chef::Node]
      def initialize(node, run_context)
        raise "#{self.class}#initialize must be implemented"
      end

      # Return the machine options to use.
      #
      # @return [Hash] the machine_options for the specific driver
      def machine_options # rubocop:disable Lint/UnusedMethodArgument
        raise "#{self.class}#machine_options must be implemented"
      end

      # Create a array of machine_options specifics to a component
      #
      # @param component [String] component name
      # @param count [Integer] component number
      # @return [Array] specific machine_options for the specific component
      def specific_machine_options(component, count = nil) # rubocop:disable Lint/UnusedMethodArgument
        raise "#{self.class}#specific_machine_options must be implemented"
      end

      # Return the Provisioning Driver Name.
      #
      # @return [String] the provisioning driver name
      def driver
        raise "#{self.class}#driver must be implemented"
      end

      # Return the ipaddress from the machine.
      #
      # @param node [Chef::Node]
      # @return [String] an ipaddress
      def ipaddress(node, use_private_ip_for_ssh = false) # rubocop:disable Lint/UnusedMethodArgument
        raise "#{self.class}#ipaddress must be implemented"
      end

    end
  end
end
