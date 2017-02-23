#
# Cookbook Name:: delivery-cluster
# Library:: helpers_insights
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright:: Copyright (c) 2016 Chef Software, Inc.
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
    # Insights Module
    #
    # This module provides helpers related to the Insights Component
    module Insights
      module_function

      # Print pretty Insights Config
      #
      # @param node [Chef::Node] Chef Node object
      def pretty_insights_config(node)
        return {} unless insights_enabled?(node)
        rabbitmq = config_with_vip(node)
        puts <<-EOF
Enable Insights:

To enable Insights on the existing chef-server, please modify the `/etc/opscode/chef-server.rb`
file by adding the following config:
------------------------------------------------------------------------------------
external_rabbitmq['enable'] = true
external_rabbitmq['actions_vhost'] = '#{rabbitmq['vhost']}}'
external_rabbitmq['actions_exchange'] = '#{rabbitmq['exchange']}'
external_rabbitmq['vip'] = '#{rabbitmq['vip']}'
external_rabbitmq['node_port'] = '#{rabbitmq['port']}'
external_rabbitmq['actions_user'] = '#{rabbitmq['user']}'
external_rabbitmq['actions_password'] = '#{rabbitmq['password']}'
------------------------------------------------------------------------------------

After that, run a reconfigure for Core and Reporting addons in the chef-server:
------------------------------------------------------------------------------------
chef-server-ctl reconfigure
opscode-reporting-ctl reconfigure
------------------------------------------------------------------------------------
        EOF
      end

      # Generates the Insights Config
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Hash] Insights attributes
      def insights_config(node)
        return {} unless insights_enabled?(node)

        Chef::Mixin::DeepMerge.hash_only_merge(
          DeliveryCluster::Helpers::Component.component_attributes(node, 'insights'),
          'chef-server-12' => {
            'insights' => {
              'rabbitmq' => config_with_vip(node),
            },
          }
        )
      end

      # Populate the Insights configuration with the FQDN of the Delivery Server
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Hash] the rabbitmq portion of the node object
      def config_with_vip(node)
        node.set['delivery-cluster']['insights']['rabbitmq']['vip'] = DeliveryCluster::Helpers::Delivery.delivery_server_fqdn(node)
        node['delivery-cluster']['insights']['rabbitmq']
      end

      # Activate the Insights Component
      # This method will touch a lock file to activate the insights component
      #
      # @param node [Chef::Node] Chef Node object
      def activate_insights(node)
        raise "You can't activate Insights when Analytics is already active." if DeliveryCluster::Helpers::Analytics.analytics_enabled?(node)
        FileUtils.touch(insights_lock_file(node))
      end

      # Insights Lock File
      #
      # @param node [Chef::Node] Chef Node object
      # @return [String] The PATH of the Insights lock file
      def insights_lock_file(node)
        "#{DeliveryCluster::Helpers.cluster_data_dir(node)}/insights"
      end

      # Verify the state of the insights Component
      # If the lock file exist, then we have the insights component enabled,
      # otherwise it is NOT enabled yet.
      #
      # @param node [Chef::Node] Chef Node object
      # @return [Bool] The state of the insights component
      def insights_enabled?(node)
        File.exist?(insights_lock_file(node))
      end
    end
  end

  # Module that exposes multiple helpers
  module DSL
    # Print pretty Insights Config
    def pretty_insights_config
      DeliveryCluster::Helpers::Insights.pretty_insights_config(node)
    end

    # Generates the Insights Config
    def insights_config
      DeliveryCluster::Helpers::Insights.insights_config(node)
    end

    # Activate the Insights Component
    def activate_insights
      DeliveryCluster::Helpers::Insights.activate_insights(node)
    end

    # Insights Lock File
    def insights_lock_file
      DeliveryCluster::Helpers::Insights.insights_lock_file(node)
    end

    # Verify the state of the Insights Component
    def insights_enabled?
      DeliveryCluster::Helpers::Insights.insights_enabled?(node)
    end
  end
end
