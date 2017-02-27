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

      # Returns Builders files to upload
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Hash] Builders files to upload through a machine resource
      def builders_files(node)
        builders_files = {
          '/etc/chef/encrypted_data_bag_secret' => "#{DeliveryCluster::Helpers.cluster_data_dir(node)}/encrypted_data_bag_secret",
        }

        Dir.glob("#{Chef::Config[:trusted_certs_dir]}/*").each do |cert_path|
          builders_files.merge!(
            ::File.join('/etc/chef/trusted_certs', ::File.basename(cert_path)) => cert_path
          )
        end

        builders_files
      end

      # Generates the Builders Attributes
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Hash] Builders attributes for a machine resource
      def builders_attributes(node)
        builders_attributes = DeliveryCluster::Helpers::Component.component_attributes(node, 'builders')

        # Add cli attributes if they exists
        unless node['delivery-cluster']['builders']['delivery-cli'].empty?
          builders_attributes = Chef::Mixin::DeepMerge.hash_only_merge(
            builders_attributes,
            'delivery_build' => {
              'delivery-cli' => node['delivery-cluster']['builders']['delivery-cli'],
            }
          )
        end

        # Add chefdk_version attribute if it exist
        if node['delivery-cluster']['builders']['chefdk_version']
          builders_attributes = Chef::Mixin::DeepMerge.hash_only_merge(
            builders_attributes,
            'delivery_build' => {
              'chefdk_version' => node['delivery-cluster']['builders']['chefdk_version'],
            }
          )
        end

        # Add trusted_certs attributes
        builders_attributes = Chef::Mixin::DeepMerge.hash_only_merge(
          builders_attributes,
          trusted_certs_attributes(node)
        )

        builders_attributes
      end

      # Generate trusted_certs attributes to send to `delivery_build` cookbook
      #
      # As part of our cookbook workflow in Delivery, we need to have a
      # Supermarket Server for cookbook resolution, this process is being
      # done by `berkshelf` which needs to have the Supermarket cert in the
      # `cacert.pem` within `chefdk`.
      #
      # Besides the Supermarket Cert, we also need to have a method to add
      # certificates for enterprises that need to sign every request that goes
      # to the internet.
      #
      # Here we are passing those certs to the `delivery_build` cookbook so it
      # can append the cert to every build node
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Hash] trusted_certs attributes
      def trusted_certs_attributes(node)
        trusted_certs_list = {}

        # Adding any global certificate
        unless node['delivery-cluster']['trusted_certs'].empty?
          global_trusted_certs = {}

          # Append the location where we will be uploading the certs
          node['delivery-cluster']['trusted_certs'].each do |name, cert|
            global_trusted_certs[name] = "/etc/chef/trusted_certs/#{cert}"
          end

          trusted_certs_list.merge!(global_trusted_certs)
        end

        # Adding the Delivery Cert
        delivery_fqdn = DeliveryCluster::Helpers::Delivery.delivery_server_fqdn(node)
        trusted_certs_list['Delivery Server Cert'] = "/etc/chef/trusted_certs/#{delivery_fqdn}.crt"

        # Adding the Chef Server Cert
        chef_server_fqdn = DeliveryCluster::Helpers::ChefServer.chef_server_fqdn(node)
        trusted_certs_list['Chef Server Cert'] = "/etc/chef/trusted_certs/#{chef_server_fqdn}.crt"

        # Adding the Supermarket Cert if it exists
        if DeliveryCluster::Helpers::Supermarket.supermarket_enabled?(node)
          supermarket_server_fqdn = DeliveryCluster::Helpers::Supermarket.supermarket_server_fqdn(node)
          trusted_certs_list['Supermarket Server'] = "/etc/chef/trusted_certs/#{supermarket_server_fqdn}.crt"
        end

        { 'delivery_build' => { 'trusted_certs' => trusted_certs_list } }
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

    # Returns Builders files to upload
    def builders_files
      DeliveryCluster::Helpers::Builders.builders_files(node)
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
