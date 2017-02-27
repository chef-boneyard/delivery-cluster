#
# Cookbook Name:: delivery-cluster
# Library:: helpers
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

require 'openssl'
require 'fileutils'
require 'securerandom'

module DeliveryCluster
  #
  # Helpers Module for general purposes
  #
  module Helpers
    module_function

    # Retrive the common cluster recipes
    #
    # This helper will return the common cluster recipes that customers specify in the
    # attribute `['delivery-cluster']['common_cluster_recipes']` plus the ones that
    # Chef considered as default/needed. Those recipes will be included to the run_list
    # of all the servers of the delivery-cluster.
    def common_cluster_recipes(node)
      default_cluster_recipes + node['delivery-cluster']['common_cluster_recipes']
    end

    # Retrive the default cluster recipes
    #
    # Return the default cluster recipes from Chef. These recipes are the ones we
    # internally need to let delivery-cluster work properly.
    #
    # To add more recipes, simply include them to the array.
    def default_cluster_recipes
      ['delivery-cluster::pkg_repo_management']
    end

    # Provisioning Driver Instance
    #
    # @param node [Chef::Node] Chef Node object
    # @return [DeliveryCluster::Provisioning::Base] provisioning driver instance
    def provisioning(node)
      check_attribute?(node['delivery-cluster']['driver'], "node['delivery-cluster']['driver']")
      @provisioning ||= DeliveryCluster::Provisioning.for_driver(node['delivery-cluster']['driver'], node)
    end

    # The current directory PATH
    # This is coming from the .chef/knife.rb
    #
    # @return [String] current directory path
    def current_dir
      Chef::Config.chef_repo_path
    end

    # Cluster Data directory link
    #
    # @return [Bool] True if cluster directory is a link, False if not
    def cluster_data_dir_link?
      File.symlink?(File.join(current_dir, '.chef', 'delivery-cluster-data'))
    end

    # Delivery Cluster data directory
    #
    # @param node [Chef::Node] Chef Node object
    # @return [String] PATH of the Delivery cluster data directory
    def cluster_data_dir(node)
      File.join(current_dir, '.chef', "delivery-cluster-data-#{delivery_cluster_id(node)}")
    end

    # Use the Private IP for SSH
    #
    # @param node [Chef::Node] Chef Node object
    # @return [Bool] True if we need to use the private ip for ssh, False if not
    def use_private_ip_for_ssh(node)
      check_attribute?(node['delivery-cluster']['driver'], "node['delivery-cluster']['driver']")
      node['delivery-cluster'][node['delivery-cluster']['driver']]['use_private_ip_for_ssh']
    end

    # Get the IP address from the Provisioning Abstraction
    #
    # @param node [Chef::Node] Chef Node object
    # @param machine_node [Chef::Node][Hash] Chef Node or Hash object of the machine we would like
    #                                        to get the ipaddress from
    # @return [String] ip address
    def get_ip(node, machine_node)
      # Inflate the `machine_node` is it is a Hash Object
      # In the future we might need to substitute this for `Chef::Node.from_hash`
      machine_node = Chef::Node.json_create(machine_node) if machine_node.class.eql?(Hash)
      provisioning(node).ipaddress(machine_node)
    end

    # Extracting the username from the provisioning abstraction
    #
    # @param node [Chef::Node] Chef Node object
    # @return [String] username
    def username(node)
      provisioning(node).username
    end

    # Delivery Cluster ID
    # If a cluster id was not provided (via the attribute) we'll generate
    # a unique cluster id and immediately save it in case the CCR fails.
    #
    # @param node [Chef::Node] Chef Node object
    # @return [String] cluster id
    def delivery_cluster_id(node)
      unless node['delivery-cluster']['id']
        node.set['delivery-cluster']['id'] = "test-#{SecureRandom.hex(3)}"
        node.save
      end

      node['delivery-cluster']['id']
    end

    # Encrypted Data Bag Secret
    # Generate or load an existing encrypted data bag secret
    #
    # @param node [Chef::Node] Chef Node object
    # @return [String] encrypted data bag secret
    def encrypted_data_bag_secret(node)
      @encrypted_data_bag_secret ||= begin
        if File.exist?("#{cluster_data_dir(node)}/encrypted_data_bag_secret")
          File.read("#{cluster_data_dir(node)}/encrypted_data_bag_secret")
        else
          # Ruby's `SecureRandom` module uses OpenSSL under the covers
          SecureRandom.base64(512)
        end
      end
    end

    # Generate Knife Variables
    # to use them to create a new knife config file that will point at the new
    # delivery cluster to facilitate its management within the `cluster_data_dir`
    #
    # @param node [Chef::Node] Chef Node object
    # @return [Hash] knife variables to render a customized knife.rb
    def knife_variables(node)
      {
        chef_server_url:      DeliveryCluster::Helpers::ChefServer.chef_server_url(node),
        client_key:           "#{cluster_data_dir(node)}/delivery.pem",
        analytics_server_url: if DeliveryCluster::Helpers::Analytics.analytics_enabled?(node)
                                "https://#{DeliveryCluster::Helpers::Analytics.analytics_server_fqdn(node)}/organizations" \
                                "/#{node['delivery-cluster']['chef-server']['organization']}"
                              else
                                ''
                              end,
        supermarket_site:     if DeliveryCluster::Helpers::Supermarket.supermarket_enabled?(node)
                                "https://#{DeliveryCluster::Helpers::Supermarket.supermarket_server_fqdn(node)}"
                              else
                                ''
                              end,
      }
    end

    # Validate License File
    # Because Delivery requires a license, we want to make sure that the
    # user has the necessary license file on the provisioning node before we begin.
    # This method will check for the license file in the compile phase to prevent
    # any work being done if the user doesn't even have a license.
    #
    # @param node [Chef::Node] Chef Node object
    def validate_license_file(node)
      return unless node['delivery-cluster']['delivery']['license_file'].nil?
      raise DeliveryCluster::Exceptions::LicenseNotFound, "node['delivery-cluster']['delivery']['license_file']"
    end

    # Validate Attribute
    # As we depend on many attributes for multiple components we need a
    # quick way to validate when they have been set or not.
    #
    # @param attr_value [NotNilValue] The value of the attribute we want to check
    # @param attr_name [String] The name of the attribute
    def check_attribute?(attr_value, attr_name)
      raise DeliveryCluster::Exceptions::AttributeNotFound, attr_name if attr_value.nil?
    end
  end

  # Module that exposes multiple helpers
  module DSL
    # Retrive the common cluster recipes
    def common_cluster_recipes
      DeliveryCluster::Helpers.common_cluster_recipes(node)
    end

    # Provisioning Driver Instance
    def provisioning
      DeliveryCluster::Helpers.provisioning(node)
    end

    # The current directory PATH
    def current_dir
      DeliveryCluster::Helpers.current_dir
    end

    # Cluster Data directory link
    def cluster_data_dir_link?
      DeliveryCluster::Helpers.cluster_data_dir_link?
    end

    # Delivery Cluster data directory
    def cluster_data_dir
      DeliveryCluster::Helpers.cluster_data_dir(node)
    end

    # Use the Private IP for SSH
    def use_private_ip_for_ssh
      DeliveryCluster::Helpers.use_private_ip_for_ssh(node)
    end

    # Get the IP address from the Provisioning Abstraction
    def get_ip(machine_node)
      DeliveryCluster::Helpers.get_ip(node, machine_node)
    end

    # Extracting the username from the provisioning abstraction
    def username
      DeliveryCluster::Helpers.username(node)
    end

    # Delivery Cluster ID
    def delivery_cluster_id
      DeliveryCluster::Helpers.delivery_cluster_id(node)
    end

    # Encrypted Data Bag Secret
    def encrypted_data_bag_secret
      DeliveryCluster::Helpers.encrypted_data_bag_secret(node)
    end

    # Generate Knife Variables
    def knife_variables
      DeliveryCluster::Helpers.knife_variables(node)
    end

    # Validate License File
    def validate_license_file
      DeliveryCluster::Helpers.validate_license_file(node)
    end
  end
end
