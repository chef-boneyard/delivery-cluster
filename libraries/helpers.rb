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
  # Helpers Module for general purposes
  module Helpers
    module_function

    # Retrive the common cluster recipes
    #
    # This helper will return the common cluster recipes that customers specify in the
    # attribute `['delivery-cluster']['common_cluster_recipes']` plus the ones that
    # Chef considered as default/needed. Those recipes will be included to the run_list
    # of all the servers of the delivery-cluster.
    def common_cluster_recipes
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

    def provisioning(node)
      fail "Driver not specified. (node['delivery-cluster']['driver'])" unless node['delivery-cluster']['driver']
      @provisioning ||= DeliveryCluster::Provisioning.for_driver(node['delivery-cluster']['driver'], node)
    end

    def current_dir
      Chef::Config.chef_repo_path
    end

    def cluster_data_dir_link?
      File.symlink?(File.join(current_dir, '.chef', 'delivery-cluster-data'))
    end

    def cluster_data_dir(node)
      File.join(current_dir, '.chef', "delivery-cluster-data-#{delivery_cluster_id(node)}")
    end

    def use_private_ip_for_ssh
      node['delivery-cluster'][node['delivery-cluster']['driver']]['use_private_ip_for_ssh']
    end

    # We will return the right IP to use depending wheter we need to
    # use the Private IP or the Public IP
    def get_ip(node)
      provisioning(node).ipaddress(node)
    end

    # Extracting the username from the provisioning abstraction
    def username(node)
      provisioning(node).username
    end

    # If a cluster ID was not provided (via the attribute) we'll generate
    # a unique cluster ID and immediately save it in case the CCR fails.
    def delivery_cluster_id(node)
      unless node['delivery-cluster']['id']
        node.set['delivery-cluster']['id'] = "test-#{SecureRandom.hex(3)}"
        node.save
      end

      node['delivery-cluster']['id']
    end

    def delivery_builder_hostname(index)
      unless node['delivery-cluster']['builders']['hostname_prefix']
        node.set['delivery-cluster']['builders']['hostname_prefix'] = "build-node-#{delivery_cluster_id}"
      end

      "#{node['delivery-cluster']['builders']['hostname_prefix']}-#{index}"
    end

    def builder_private_key
      File.read(File.join(cluster_data_dir, 'builder_key'))
    end

    def builder_run_list
      @builder_run_list ||= begin
        base_builder_run_list = %w( recipe[push-jobs] recipe[delivery_build] )
        base_builder_run_list + node['delivery-cluster']['builders']['additional_run_list']
      end
    end

    # Generate or load an existing encrypted data bag secret
    def encrypted_data_bag_secret
      if File.exist?("#{cluster_data_dir}/encrypted_data_bag_secret")
        File.read("#{cluster_data_dir}/encrypted_data_bag_secret")
      else
        # Ruby's `SecureRandom` module uses OpenSSL under the covers
        SecureRandom.base64(512)
      end
    end

    def builders_attributes
      builders_attributes = {}

      # Add cli attributes if they exists.
      builders_attributes['delivery_build'] = { 'delivery-cli' => node['delivery-cluster']['builders']['delivery-cli'] } unless node['delivery-cluster']['builders']['delivery-cli'].empty?

      builders_attributes
    end

    # Render a knife config file that points at the new delivery cluster
    def render_knife_config
      template File.join(cluster_data_dir, 'knife.rb') do
        variables lazy {
          {
            chef_server_url:      chef_server_url,
            client_key:           "#{cluster_data_dir}/delivery.pem",
            analytics_server_url: if analytics_enabled?
                                    "https://#{analytics_server_fqdn}/organizations" \
                                    "/#{node['delivery-cluster']['chef-server']['organization']}"
                                  else
                                    ''
                                  end,
            supermarket_site:     supermarket_enabled? ? "https://#{supermarket_server_fqdn}" : ''
          }
        }
      end
    end

    # Because Delivery requires a license, we want to make sure that the
    # user has the necessary license file on the provisioning node before we begin.
    # This method will check for the license file in the compile phase to prevent
    # any work being done if the user doesn't even have a license.
    def validate_license_file
      msg_delim = '***************************************************'

      contact_msg = <<-END

#{msg_delim}

Chef Delivery requires a valid license to run.
To acquire a license, please contact your CHEF
account representative.

      END

      fail "#{contact_msg}Please set `#{node['delivery-cluster']['delivery']['license_file']}`\n" \
            "in your environment file.\n\n#{msg_delim}" if node['delivery-cluster']['delivery']['license_file'].nil?
    end
  end

  # Module that exposes multiple helpers
  # module DSL

  # end
end
