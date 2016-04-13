#
# Cookbook Name:: delivery-cluster
# Library:: helpers_delivery
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
    # Delivery Module
    #
    # This module provides helpers related to the Delivery Component
    module Delivery
      module_function

      # Get the Hostname of the Delivery Server
      #
      # @param node [Chef::Node] Chef Node object
      # @return hostname [String] The hostname of the Delivery server
      def delivery_server_hostname(node)
        DeliveryCluster::Helpers::Component.component_hostname(node, 'delivery')
      end

      # Get the Hostname of the Delivery Server
      #
      # @param node [Chef::Node] Chef Node object
      # @return hostname [String] The hostname of the Delivery Dr Server
      def delivery_server_dr_hostname(node)
        DeliveryCluster::Helpers::Component.component_hostname(node, 'delivery', 'disaster_recovery')
      end

      # Returns the FQDN of the Delivery Server
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] Delivery FQDN
      def delivery_server_fqdn(node)
        @delivery_server_fqdn ||= DeliveryCluster::Helpers::Component.component_fqdn(node, 'delivery')
      end

      # Returns the IP of the Delivery Server
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] Delivery IP
      def delivery_server_ip(node)
        @delivery_server_ip ||= DeliveryCluster::Helpers::Component.component_ip(node, 'delivery')
      end

      # Returns the IP of the Delivery Standby Server
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] Delivery Standby IP
      def delivery_standby_ip(node)
        @delivery_standby_ip ||= DeliveryCluster::Helpers::Component.component_ip(node, 'delivery', 'disaster_recovery')
      end

      # Generates the Delivery Server Attributes
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Hash] Delivery attributes for a machine resource
      def delivery_server_attributes(node, type = nil)
        # Configuring the chef-server url for delivery
        node.set['delivery-cluster']['delivery']['chef_server'] = DeliveryCluster::Helpers::ChefServer.chef_server_url(node) unless node['delivery-cluster']['delivery']['chef_server']

        # Ensure we have a Delivery FQDN
        node.set['delivery-cluster']['delivery']['fqdn'] = delivery_server_fqdn(node) unless node['delivery-cluster']['delivery']['fqdn']

        unless type.nil?
          # We use node.default here so if the user edits the env file we revert to defaults.
          # Store the ips for the DR configuration
          node.default['delivery-cluster']['delivery']['ip'] = delivery_server_ip(node) unless node['delivery-cluster']['delivery']['ip']
          node.default['delivery-cluster']['delivery']['disaster_recovery']['ip'] = delivery_standby_ip(node) unless node['delivery-cluster']['delivery']['disaster_recovery']['ip']
          case type
          when :primary
            node.default['delivery-cluster']['delivery']['primary'] = true
            node.default['delivery-cluster']['delivery']['standby'] = false
          when :standby
            node.default['delivery-cluster']['delivery']['primary'] = false
            node.default['delivery-cluster']['delivery']['standby'] = true
          else
            raise "Unknown Server type #{type}"
          end
        end

        Chef::Mixin::DeepMerge.hash_only_merge(
          { 'delivery-cluster' => node['delivery-cluster'] },
          DeliveryCluster::Helpers::Component.component_attributes(node, 'delivery')
        )
      end

      # Return the delivery-ctl command
      # The delivery-ctl needs to be executed with elevated privileges
      # we validate the user that is coming from the provisioning abstraction
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] delivery-ctl command
      def delivery_ctl(node)
        DeliveryCluster::Helpers.username(node) == 'root' ? 'delivery-ctl' : 'sudo -E delivery-ctl'
      end

      # Return the command to create an enterprise
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] delivery-ctl command to create an enterprise
      def delivery_enterprise_cmd(node)
        # Validating that the enterprise does not already exist
        cmd = <<-CMD.gsub(/\s+/, ' ').strip!
          #{delivery_ctl(node)} list-enterprises | grep -w ^#{node['delivery-cluster']['delivery']['enterprise']};
          [ $? -ne 0 ] && #{delivery_ctl(node)} create-enterprise #{node['delivery-cluster']['delivery']['enterprise']}
        CMD
        # We have introduced an additional constrain to the enterprise_ctl
        # command that require to specify --ssh-pub-key-file param starting
        # from the Delivery Version 0.2.52
        if node['delivery-cluster']['delivery']['version'] == 'latest' ||
           Gem::Version.new(node['delivery-cluster']['delivery']['version']) > Gem::Version.new('0.2.52')
          cmd << ' --ssh-pub-key-file=/etc/delivery/builder_key.pub'
        end
        cmd << " > /tmp/#{node['delivery-cluster']['delivery']['enterprise']}.creds || echo 1"
      end
    end
  end

  # Module that exposes multiple helpers
  module DSL
    # Hostname of the Delivery Server
    def delivery_server_hostname
      DeliveryCluster::Helpers::Delivery.delivery_server_hostname(node)
    end

    # Hostname of the Delivery Dr Server
    def delivery_server_dr_hostname
      DeliveryCluster::Helpers::Delivery.delivery_server_dr_hostname(node)
    end

    # FQDN of the Delivery Server
    def delivery_server_fqdn
      DeliveryCluster::Helpers::Delivery.delivery_server_fqdn(node)
    end

    # IP of the Delivery Server
    def delivery_server_ip
      DeliveryCluster::Helpers::Delivery.delivery_server_ip(node)
    end

    # IP of the Delivery Standby Server
    def delivery_standby_ip
      DeliveryCluster::Helpers::Delivery.delivery_standby_ip(node)
    end

    # Delivery Server Attributes
    def delivery_server_attributes(type = nil)
      DeliveryCluster::Helpers::Delivery.delivery_server_attributes(node, type)
    end

    # Delivery Artifact
    def delivery_artifact
      DeliveryCluster::Helpers::Delivery.delivery_artifact(node)
    end

    # Return the delivery-ctl command
    def delivery_ctl
      DeliveryCluster::Helpers::Delivery.delivery_ctl(node)
    end

    # Return the command to create an enterprise
    def delivery_enterprise_cmd
      DeliveryCluster::Helpers::Delivery.delivery_enterprise_cmd(node)
    end
  end
end
