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

      # Returns the FQDN of the Delivery Server
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] Delivery FQDN
      def delivery_server_fqdn(node)
        @delivery_server_fqdn ||= DeliveryCluster::Helpers::Component.component_fqdn(node, 'delivery')
      end

      # Generates the Delivery Server Attributes
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Hash] Delivery attributes for a machine resource
      def delivery_server_attributes(node)
        # If we want to pull down the packages from Chef Artifactory
        if node['delivery-cluster']['delivery']['artifactory']
          artifact = delivery_artifact(node)
          node.set['delivery-cluster']['delivery']['version']   = artifact['version']
          node.set['delivery-cluster']['delivery']['artifact']  = artifact['artifact']
          node.set['delivery-cluster']['delivery']['checksum']  = artifact['checksum']
        end

        # Configuring the chef-server url for delivery
        node.set['delivery-cluster']['delivery']['chef_server'] = DeliveryCluster::Helpers::ChefServer.chef_server_url(node) unless node['delivery-cluster']['delivery']['chef_server']

        # Ensure we have a Delivery FQDN
        node.set['delivery-cluster']['delivery']['fqdn'] = delivery_server_fqdn(node) unless node['delivery-cluster']['delivery']['fqdn']

        Chef::Mixin::DeepMerge.hash_only_merge(
          { 'delivery-cluster' => node['delivery-cluster'] },
          DeliveryCluster::Helpers::Component.component_attributes(node, 'delivery')
        )
      end

      # Delivery Artifact
      # We will get the Delivery Package from artifactory (Require Chef VPN)
      #
      # Get the latest artifact:
      # => artifact = get_delivery_artifact('latest', 'redhat', '6.5')
      #
      # Get specific artifact:
      # => artifact = get_delivery_artifact('0.2.21', 'ubuntu', '12.04', '/var/tmp')
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Hash] Delivery Artifact
      def delivery_artifact(node)
        @delivery_artifact ||= begin
          artifact = get_delivery_artifact(
            node,
            node['delivery-cluster']['delivery']['version'],
            DeliveryCluster::Helpers::Component.component_node(node, 'delivery')['platform'],
            DeliveryCluster::Helpers::Component.component_node(node, 'delivery')['platform_version'],
            node['delivery-cluster']['delivery']['pass-through'] ? nil : DeliveryCluster::Helpers.cluster_data_dir(node)
          )

          delivery_artifact = {
            'version'  => artifact['version'],
            'checksum' => artifact['checksum']
          }
          # Upload Artifact to Delivery Server only if we have donwloaded the artifact
          if artifact['local_path']
            machine_file = Chef::Resource::MachineFile.new("/var/tmp/#{artifact['name']}", run_context)
            machine_file.chef_server(DeliveryCluster::Helpers::ChefServer.chef_server_config(node))
            machine_file.machine(node['delivery-cluster']['delivery']['hostname'])
            machine_file.local_path(artifact['local_path'])
            machine_file.run_action(:upload)

            delivery_artifact['artifact'] = "/var/tmp/#{artifact['name']}"
          else
            delivery_artifact['artifact'] = artifact['uri']
          end

          delivery_artifact
        end
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

    # FQDN of the Delivery Server
    def delivery_server_fqdn
      DeliveryCluster::Helpers::Delivery.delivery_server_fqdn(node)
    end

    # Delivery Server Attributes
    def delivery_server_attributes
      DeliveryCluster::Helpers::Delivery.delivery_server_attributes(node)
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
