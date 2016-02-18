#
# Cookbook Name:: delivery-cluster
# Library:: base
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
module DeliveryCluster
  module Provisioning
    #
    # Base class for a Provisioning Abstraction.
    #
    # Specify all the methods a Provisioning Driver should implement
    # @author Salim Afiune <afiune@chef.io>
    class Base
      # Create a new Provisioning Driver Abstraction
      #
      # @param node [Chef::Node]
      def initialize(node) # rubocop:disable Lint/UnusedMethodArgument
        raise "#{self.class}#initialize must be implemented"
      end

      # Return the machine options to use.
      #
      # @return [Hash] the machine_options for the specific driver
      def machine_options
        raise "#{self.class}#machine_options must be implemented"
      end

      # Create a array of machine_options specifics to a component
      #
      # @param component [String] component name
      # @param count [Integer] component number
      # @return [Array] specific machine_options for the specific component
      def specific_machine_options(_component, _count = nil)
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

      # Return the username of the Provisioning Driver.
      #
      # @return [String] the username
      def username
        'root'
      end
    end
  end
end
