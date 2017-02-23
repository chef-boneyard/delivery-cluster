#
# Cookbook Name:: delivery-cluster
# Library:: helpers_chef_server
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

require 'securerandom'

module DeliveryCluster
  module Helpers
    #
    # ChefServer Module
    #
    # This module provides helpers related to the Chef Server Component
    module ChefServer
      module_function

      # Password of the Delivery User
      # Generate or load the password of the delivery user in the chef-server
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] password of the delivery user
      def chef_server_delivery_password(node)
        @chef_server_delivery_password ||= begin
          if File.exist?("#{DeliveryCluster::Helpers.cluster_data_dir(node)}/chef_server_delivery_password")
            File.read("#{DeliveryCluster::Helpers.cluster_data_dir(node)}/chef_server_delivery_password")
          elsif node['delivery-cluster']['chef-server']['delivery_password']
            node['delivery-cluster']['chef-server']['delivery_password']
          else
            SecureRandom.base64(20)
          end
        end
      end

      # Upload a specific cookbook to our chef-server
      #
      # @param node [Chef::Node] Chef Node object
      # @param cookbook [String] Cookbook Name
      def upload_cookbook(node, cookbook)
        execute "Upload Cookbook => #{cookbook}" do
          command "knife cookbook upload #{cookbook} --cookbook-path #{Chef::Config[:cookbook_path]}"
          environment(
            'KNIFE_HOME' => DeliveryCluster::Helpers.cluster_data_dir(node)
          )
          not_if "knife cookbook show #{cookbook}"
        end
      end

      # Get the Hostname of the Chef Server
      #
      # @param node [Chef::Node] Chef Node object
      # @return hostname [String] The hostname of the chef-server
      def chef_server_hostname(node)
        DeliveryCluster::Helpers::Component.component_hostname(node, 'chef-server')
      end

      # Returns the FQDN of the Chef Server
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String]
      def chef_server_fqdn(node)
        @chef_server_fqdn ||= begin
          chef_server_node = Chef::Node.load(chef_server_hostname(node))
          DeliveryCluster::Helpers::Component.component_fqdn(node, 'chef-server', chef_server_node)
        end
      end

      # Returns the Chef Server URL of our Organization
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] chef-server url
      def chef_server_url(node)
        "https://#{chef_server_fqdn(node)}/organizations/#{node['delivery-cluster']['chef-server']['organization']}"
      end

      # Generates the Chef Server Attributes
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Hash] chef-server attributes
      def chef_server_attributes(node)
        @chef_server_attributes = {
          'chef-server-12' => {
            'accept_license' => node['delivery-cluster']['accept_license'],
            'delivery' => {
              'organization' => node['delivery-cluster']['chef-server']['organization'],
              'password' => chef_server_delivery_password(node),
            },
            'api_fqdn' => chef_server_fqdn(node),
            'store_keys_databag' => false,
            'plugin' => {
              'reporting' => node['delivery-cluster']['chef-server']['enable-reporting'],
            },
            'data_collector' => {
              'root_url' => node['delivery-cluster']['chef-server']['data_collector']['root_url'],
              'token' => node['delivery-cluster']['chef-server']['data_collector']['token'],
            },
          },
        }
        @chef_server_attributes = Chef::Mixin::DeepMerge.hash_only_merge(
          @chef_server_attributes,
          DeliveryCluster::Helpers::Analytics.analytics_server_attributes(node)
        )
        @chef_server_attributes = Chef::Mixin::DeepMerge.hash_only_merge(
          @chef_server_attributes,
          DeliveryCluster::Helpers::Supermarket.supermarket_server_attributes(node)
        )
        @chef_server_attributes = Chef::Mixin::DeepMerge.hash_only_merge(
          @chef_server_attributes,
          DeliveryCluster::Helpers::Component.component_attributes(node, 'chef-server')
        )
        @chef_server_attributes = Chef::Mixin::DeepMerge.hash_only_merge(
          @chef_server_attributes,
          DeliveryCluster::Helpers::Insights.insights_config(node)
        )
        @chef_server_attributes
      end

      # Chef Server Config
      # This is used by all the `machine` resources to point to our chef-server
      # and any interaction we have with the chef-server like data-bags, roles, etc.
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Hash] chef-server attributes
      def chef_server_config(node)
        {
          chef_server_url: chef_server_url(node),
          options: {
            client_name: 'delivery',
            signing_key_filename: "#{DeliveryCluster::Helpers.cluster_data_dir(node)}/delivery.pem",
          },
        }
      end
    end
  end

  # Module that exposes multiple helpers
  module DSL
    # Password of the Delivery User
    def chef_server_delivery_password
      DeliveryCluster::Helpers::ChefServer.chef_server_delivery_password(node)
    end

    # Return the chef-server config
    def upload_cookbook(cookbook)
      DeliveryCluster::Helpers::ChefServer.upload_cookbook(node, cookbook)
    end

    # Get the Hostname of the Chef Server
    def chef_server_hostname
      DeliveryCluster::Helpers::ChefServer.chef_server_hostname(node)
    end

    # Return the chef-server config
    def chef_server_config
      DeliveryCluster::Helpers::ChefServer.chef_server_config(node)
    end

    # Return the FQDN of the Chef Server
    def chef_server_fqdn
      DeliveryCluster::Helpers::ChefServer.chef_server_fqdn(node)
    end

    # Return the Chef Server URL of our Organization
    def chef_server_url
      DeliveryCluster::Helpers::ChefServer.chef_server_url(node)
    end

    # Generate the Chef Server Attributes
    def chef_server_attributes
      DeliveryCluster::Helpers::ChefServer.chef_server_attributes(node)
    end
  end
end
