#
# Cookbook Name:: delivery-cluster
# Library:: helpers_delivery_dr
#
# Author:: Jon Morrow (<jmorrow@chef.io>)
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
    # Delivery DR Module
    #
    # This module provides helpers related to the Delivery Dr Setup
    module DeliveryDR
      module_function

      # Retrieve the Delivery Primary Key Name
      #
      # @return [String] the Delivery Primary Key Name
      def delivery_primary_key_name
        'delivery_primary_key'
      end

      # Retrieve the Delivery Standby Key Name
      #
      # @return [String] the Delivery Standby Key Name
      def delivery_standby_key_name
        'delivery_standby_key'
      end

      # Retrieve the Delivery Primary Private Key
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] the Delivery Primary Private Key
      def delivery_primary_private_key(node)
        File.read(File.join(DeliveryCluster::Helpers.cluster_data_dir(node), delivery_primary_key_name))
      end

      # Retrieve the Delivery Primary Public Key
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] the Delivery Primary Public Key
      def delivery_primary_public_key(node)
        File.read(File.join(DeliveryCluster::Helpers.cluster_data_dir(node), "#{delivery_primary_key_name}.pub"))
      end

      # Retrieve the Delivery Standby Private Key
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] the Delivery Standby Private Key
      def delivery_standby_private_key(node)
        File.read(File.join(DeliveryCluster::Helpers.cluster_data_dir(node), delivery_standby_key_name))
      end

      # Retrieve the Delivery Standby Public Key
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] the Delivery Standby Public Key
      def delivery_standby_public_key(node)
        File.read(File.join(DeliveryCluster::Helpers.cluster_data_dir(node), "#{delivery_standby_key_name}.pub"))
      end
    end
  end

  # Module that exposes multiple helpers
  module DSL
    # Retrieve the primary key name
    def delivery_primary_key_name
      DeliveryCluster::Helpers::DeliveryDR.delivery_primary_key_name
    end

    # Retrieve the standby key name
    def delivery_standby_key_name
      DeliveryCluster::Helpers::DeliveryDR.delivery_standby_key_name
    end

    # Retrieve the Delivery Primary Private Key
    def delivery_primary_private_key
      DeliveryCluster::Helpers::DeliveryDR.delivery_primary_private_key(node)
    end

    # Retrieve the Delivery Primary Public Key
    def delivery_primary_public_key
      DeliveryCluster::Helpers::DeliveryDR.delivery_primary_public_key(node)
    end

    # Retrieve the Delivery Standby Private Key
    def delivery_standby_private_key
      DeliveryCluster::Helpers::DeliveryDR.delivery_standby_private_key(node)
    end

    # Retrieve the Delivery Standby Public Key
    def delivery_standby_public_key
      DeliveryCluster::Helpers::DeliveryDR.delivery_standby_public_key(node)
    end
  end
end
