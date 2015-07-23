#
# Cookbook Name:: delivery-cluster
# Library:: helpers_splunk
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
  module Helpers
    #
    # Splunk Module
    #
    # This module provides helpers related to the Splunk Component
    module Splunk
      module_function

      # Get the Hostname of the Splunk Server
      #
      # @param node [Chef::Node] Chef Node object
      # @return hostname [String] The hostname of the Splunk server
      def splunk_server_hostname(node)
        DeliveryCluster::Helpers::Component.component_hostname(node, 'splunk')
      end

      # Returns the FQDN of the Splunk Server
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] Splunk FQDN
      def splunk_server_fqdn(node)
        @splunk_server_fqdn ||= DeliveryCluster::Helpers::Component.component_fqdn(node, 'splunk')
      end

      # Activate the Splunk Component
      # This method will touch a lock file to activate the Splunk component
      #
      # @param node [Chef::Node] Chef Node object
      def activate_splunk(node)
        FileUtils.touch(splunk_lock_file(node))
      end

      # Splunk Lock File
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] The PATH of the Splunk lock file
      def splunk_lock_file(node)
        "#{DeliveryCluster::Helpers.cluster_data_dir(node)}/splunk"
      end

      # Verify the state of the Splunk Component
      # If the lock file exist, then we have the Splunk component enabled,
      # otherwise it is NOT enabled yet.
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Bool] The state of the Splunk component
      def splunk_enabled?(node)
        File.exist?(splunk_lock_file(node))
      end
    end
  end

  # Module that exposes multiple helpers
  module DSL
    # Hostname of the Splunk Server
    def splunk_server_hostname
      DeliveryCluster::Helpers::Splunk.splunk_server_hostname(node)
    end

    # FQDN of the Splunk Server
    def splunk_server_fqdn
      DeliveryCluster::Helpers::Splunk.splunk_server_fqdn(node)
    end

    # Splunk Server Attributes
    def splunk_server_attributes
      DeliveryCluster::Helpers::Splunk.splunk_server_attributes(node)
    end

    # Activate the Splunk Component
    def activate_splunk
      DeliveryCluster::Helpers::Splunk.activate_splunk(node)
    end

    # Splunk Lock File
    def splunk_lock_file
      DeliveryCluster::Helpers::Splunk.splunk_lock_file(node)
    end

    # Verify the state of the Splunk Component
    def splunk_enabled?
      DeliveryCluster::Helpers::Splunk.splunk_enabled?(node)
    end
  end
end
