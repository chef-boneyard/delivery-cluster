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
require 'chef/server_api'
require 'chef/node'

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
      # @param node [Chef::Node] Chef Node object
      # @param component [String] The name of the component
      # @return node [Chef::Node] Chef Node object
      def component_node(node, component, id = nil)
        # Inflate the Hash returned from Chef::ServerAPI
        # In the future we might need to substitute this for `Chef::Node.from_hash`
        Chef::Node.json_create(
          Chef::ServerAPI.new(
            DeliveryCluster::Helpers::ChefServer.chef_server_config(node)[:chef_server_url],
            client_name: DeliveryCluster::Helpers::ChefServer.chef_server_config(node)[:options][:client_name],
            signing_key_filename: DeliveryCluster::Helpers::ChefServer.chef_server_config(node)[:options][:signing_key_filename]
          ).get("nodes/#{component_hostname(node, component, id)}")
        )
      end

      # Returns the IP of the component
      # If the component_node is specified, we use it. Otherwise we extract it
      #
      # @param node [Chef::Node] Chef Node object
      # @param component [String] The name of the component
      # @param id [String] The id to point to an specific component
      # @param component_node [Chef::Node] The Chef Node object of the component
      # @return [String]
      def component_ip(node, component, id = nil, c_node = component_node(node, component, id))
        DeliveryCluster::Helpers.check_attribute?(node['delivery-cluster'][component], "node['delivery-cluster']['#{component}']")
        if id
          node['delivery-cluster'][component][id]['ip'] ||
            DeliveryCluster::Helpers.get_ip(node, c_node)
        else
          node['delivery-cluster'][component]['ip'] ||
            DeliveryCluster::Helpers.get_ip(node, c_node)
        end
      end

      # Returns the FQDN of the component
      # If the component_node is specified, we use it. Otherwise we extract it
      #
      # @param node [Chef::Node] Chef Node object
      # @param component [String] The name of the component
      # @param component_node [Chef::Node] The Chef Node object of the component
      # @return [String]
      def component_fqdn(node, component, c_node = component_node(node, component))
        node['delivery-cluster'][component]['fqdn'] ||
          node['delivery-cluster'][component]['host'] ||
          component_ip(node, component, nil, c_node) # So a bit ikky but until we revisit this function this should make it backwards compat.
      end

      # Returns the Hostname of the component
      # If there is an `id` it means that this component consist in more than
      # one machine (multiple components of the same kind)
      #
      # @param node [Chef::Node] Chef Node object
      # @param component [String] The name of the component
      # @return [String]
      def component_hostname(node, component, id = nil)
        DeliveryCluster::Helpers.check_attribute?(node['delivery-cluster'][component], "node['delivery-cluster']['#{component}']")
        if id
          multiple_component_hostname(node, component, id)
        else
          single_component_hostname(node, component)
        end
      end

      # Returns the Hostname of the a single component
      # If the component does not have already a hostname we will generate one
      # and save it
      #
      # @param node [Chef::Node] Chef Node object
      # @param component [String] The name of the component
      # @return [String] component hostname
      def single_component_hostname(node, component)
        unless hostname?(get_component(node, component))
          component_prefix = component.eql?('chef-server') ? 'chef-server' : "#{component}-server"
          node.set['delivery-cluster'][component]['hostname'] = "#{component_prefix}-#{DeliveryCluster::Helpers.delivery_cluster_id(node)}"
        end

        get_component(node, component)['hostname']
      end

      # Returns the Hostname of a multiple component with an id
      # Where the `id` will be a pointer of one of the components that we
      # will work with. First we validate if it has a 'hostname', if not we
      # search for a 'hostname_prefix', but if we do not find any of them,
      # we will generate and save them.
      #
      # @param node [Chef::Node] Chef Node object
      # @param component [String] The name of the component
      # @param id [String] The id to point to an specific component
      # @return [String] component hostname
      def multiple_component_hostname(node, component, id)
        unless hostname?(get_component(node, component, id))
          unless node['delivery-cluster'][component]['hostname_prefix']
            component_prefix = component.eql?('builders') ? 'build-node' : "#{component}-server"
            node.set['delivery-cluster'][component]['hostname_prefix'] = "#{component_prefix}-#{DeliveryCluster::Helpers.delivery_cluster_id(node)}"
          end
          node.set['delivery-cluster'][component][id]['hostname'] = "#{node['delivery-cluster'][component]['hostname_prefix']}-#{id}"
        end

        get_component(node, component, id)['hostname']
      end

      # Returns the hostname from a Hash
      #
      # @param component [String] The component
      # @return [String] hostname
      def hostname?(component)
        component['hostname']
      end

      # Extract a component from a Chef::Node Object
      #
      # @param node [Chef::Node] Chef Node object
      # @param name [String] The name of a component
      # @param id [String] The id to point to an specific component
      # @return [String] hostname
      def get_component(node, name, id = nil)
        if id
          return {} unless node['delivery-cluster'][name][id]
          node['delivery-cluster'][name][id]
        else
          node['delivery-cluster'][name]
        end
      end

      # Returns the component attributes
      # In the case of additional attributes specified, if there aren't
      # we will return an empty Hash
      #
      # @param node [Chef::Node] Chef Node object
      # @param name [String] The name of a component
      # @return [Hash] of attributes from a component
      #
      def component_attributes(node, name)
        node['delivery-cluster'][name]['attributes']
      rescue
        {}
      end
    end
  end

  # Module that exposes multiple helpers
  module DSL
    # Extra component attributes
    def component_attributes(component)
      DeliveryCluster::Helpers::Component.component_attributes(node, component)
    end

    # The component node object
    def component_node(component)
      DeliveryCluster::Helpers::Component.component_node(node, component)
    end

    # The component fqdn
    def component_fqdn(component, component_node = nil)
      DeliveryCluster::Helpers::Component.component_fqdn(node, component, component_node)
    end

    # The component ip
    def component_ip(component, component_node = nil)
      DeliveryCluster::Helpers::Component.component_ip(node, component, component_node)
    end

    # The component hostname
    def component_hostname(component, id = nil)
      DeliveryCluster::Helpers::Component.component_hostname(node, component, id)
    end
  end
end
