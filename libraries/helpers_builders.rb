#
# Cookbook Name:: delivery-cluster
# Library:: helpers_builders
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
    # Builders Module
    #
    # This module provides helpers related to the Builders Component
    module Builders
      module_function

      # Get the Hostname of our Builders
      #
      # @param node [Chef::Node] Chef Node object
      # @param index [Number] The number of the build-node in question
      # @return hostname [String] The hostname of the build-node for a machine resource
      def delivery_builder_hostname(node, index)
        DeliveryCluster::Helpers::Component.component_hostname(node, 'builders', index.to_s)
      end

      # Generates the Builders Attributes
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Hash] Builders attributes for a machine resource
      def builders_attributes(node)
        builders_attributes = {}

        # Add cli attributes if they exists.
        builders_attributes['delivery_build'] = { 'delivery-cli' => node['delivery-cluster']['builders']['delivery-cli'] } unless node['delivery-cluster']['builders']['delivery-cli'].empty?

        builders_attributes
      end

      # Retrieve the Builder Private Key
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] the Builder Private Key
      def builder_private_key(node)
        File.read(File.join(DeliveryCluster::Helpers.cluster_data_dir(node), 'builder_key'))
      end

      # Return the run_list of the Builders
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Array] builders run_list
      def builder_run_list(node)
        @builder_run_list ||= begin
          base_builder_run_list = %w( recipe[push-jobs] recipe[delivery_build] )
          base_builder_run_list += node['delivery-cluster']['builders']['additional_run_list'] if node['delivery-cluster']['builders']['additional_run_list']
          base_builder_run_list
        end
      end
    end
  end

  # Module that exposes multiple helpers
  module DSL
    # Get the Hostname of our Builders
    def delivery_builder_hostname(index)
      DeliveryCluster::Helpers::Builders.delivery_builder_hostname(node, index)
    end

    # Generates the Builders Attributes
    def builders_attributes
      DeliveryCluster::Helpers::Builders.builders_attributes(node)
    end

    # Retrieve the Builder Private Key
    def builder_private_key
      DeliveryCluster::Helpers::Builders.builder_private_key(node)
    end

    # Return the run_list of the Builders
    def builder_run_list
      DeliveryCluster::Helpers::Builders.builder_run_list(node)
    end
  end
end
