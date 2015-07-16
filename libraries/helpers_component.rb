#
# Cookbook Name:: delivery-cluster
# Library:: helpers_component
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
    # Component Module
    #
    # This module provide helpers for the components of delivery-cluster
    module Component
      module_function

      # Extract the Chef::Node object of the component
      #
      # @param component [String] The name of the component
      # @return node [Chef::Node] Chef Node object
      def component_node(node, component)
        Chef::REST.new(
          DeliveryCluster::Helpers.chef_server_config(node)[:chef_server_url],
          DeliveryCluster::Helpers.chef_server_config(node)[:options][:client_name],
          DeliveryCluster::Helpers.chef_server_config(node)[:options][:signing_key_filename]
        ).get_rest("nodes/#{component_hostname(node, component)}")
      end

      # Returns the FQDN of the component
      # If the component_node is specified, we used. Otherwise we extract it
      #
      # @param node [Chef::Node] Chef Node object
      # @param component [String] The name of the component
      # @param component_node [Chef::Node] The Chef Node object of the component
      # @return [String]
      def component_fqdn(node, component, component_node = nil)
        component_node = component_node ? component_node : component_node(node, component)
        node['delivery-cluster'][component]['fqdn'] ||
          node['delivery-cluster'][component]['host'] ||
          DeliveryCluster::Helpers.get_ip(component_node)
      end

      # Returns the Hostname of the component
      # If the prefix is specified, we used. Otherwise we generate one
      #
      # @param node [Chef::Node] Chef Node object
      # @param component [String] The name of the component
      # @return [String]
      def component_hostname(node, component)
        unless node['delivery-cluster'][component]['hostname']
          component_prefix = component.eql?('chef-server') ? 'chef-server' : "#{component}-server"
          node.set['delivery-cluster'][component]['hostname'] = "#{component_prefix}-#{DeliveryCluster::Helpers.delivery_cluster_id(node)}"
        end

        node['delivery-cluster'][component]['hostname']
      end
    end
  end

  # Module that exposes multiple helpers
  module DSL
    # The component node object
    def component_node(component)
      DeliveryCluster::Helpers::Component.component_node(node, component)
    end

    # The component fqdn
    def component_fqdn(component, component_node = nil)
      DeliveryCluster::Helpers::Component.component_fqdn(node, component, component_node)
    end

    # The component hostname
    def component_hostname(component)
      DeliveryCluster::Helpers::Component.component_hostname(node, component)
    end
  end
end
