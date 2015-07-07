#
# Cookbook Name:: delivery-cluster
# Library:: _helper
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
  # Helper Module for general purposes
  module Helper
<<<<<<< HEAD
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
=======
    module_function
>>>>>>> Enable module_function on DeliveryCluster::Helper

    def provisioning
      @provisioning ||= DeliveryCluster::Provisioning.for_driver(node['delivery-cluster']['driver'], node)
    end

    def current_dir
      Chef::Config.chef_repo_path
    end

    def cluster_data_dir_link?
      File.symlink?(File.join(current_dir, '.chef', 'delivery-cluster-data'))
    end

    def cluster_data_dir
      File.join(current_dir, '.chef', "delivery-cluster-data-#{delivery_cluster_id}")
    end

    def use_private_ip_for_ssh
      node['delivery-cluster'][node['delivery-cluster']['driver']]['use_private_ip_for_ssh']
    end

    # We will return the right IP to use depending wheter we need to
    # use the Private IP or the Public IP
    def get_ip(node)
      provisioning.ipaddress(node)
    end

    # delivery-ctl needs to be executed with elevated privileges
    def delivery_ctl
      if node['delivery-cluster']['aws']['ssh_username'] == 'root'
        'delivery-ctl'
      else
        'sudo -E delivery-ctl'
      end
    end

    # If a cluster ID was not provided (via the attribute) we'll generate
    # a unique cluster ID and immediately save it in case the CCR fails.
    def delivery_cluster_id
      unless node['delivery-cluster']['id']
        node.set['delivery-cluster']['id'] = "test-#{SecureRandom.hex(3)}"
        node.save
      end

      node['delivery-cluster']['id']
    end

    def splunk_server_hostname
      component_hostname('splunk')
    end

    def chef_server_hostname
      component_hostname('chef-server', 'chef-server')
    end

    def delivery_server_hostname
      component_hostname('delivery')
    end

    def analytics_server_hostname
      component_hostname('analytics')
    end

    def supermarket_server_hostname
      component_hostname('supermarket')
    end

    def component_hostname(component, prefix = nil)
      unless node['delivery-cluster'][component]['hostname']
        component_prefix = prefix ? prefix : "#{component}-server"
        node.set['delivery-cluster'][component]['hostname'] = "#{component_prefix}-#{delivery_cluster_id}"
      end

      node['delivery-cluster'][component]['hostname']
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

    def analytics_lock_file
      "#{cluster_data_dir}/analytics"
    end

    def supermarket_lock_file
      "#{cluster_data_dir}/supermarket"
    end

    def splunk_lock_file
      "#{cluster_data_dir}/splunk"
    end

    def component_node(component)
      Chef::REST.new(
        chef_server_config[:chef_server_url],
        chef_server_config[:options][:client_name],
        chef_server_config[:options][:signing_key_filename]
      ).get_rest("nodes/#{component_hostname(component)}")
    end

    def chef_server_fqdn
      @chef_server_fqdn ||= begin
        chef_server_node = Chef::Node.load(chef_server_hostname)
        component_fqdn('chef-server', chef_server_node)
      end
    end

    def delivery_server_fqdn
      @delivery_server_fqdn ||= component_fqdn('delivery')
    end

    def analytics_server_fqdn
      @analytics_server_fqdn ||= component_fqdn('analytics')
    end

    def supermarket_server_fqdn
      @supermarket_server_fqdn ||= component_fqdn('supermarket')
    end

    def component_fqdn(component, component_node = nil)
      component_node = component_node ? component_node : component_node(component)
      node['delivery-cluster'][component]['fqdn'] ||
        node['delivery-cluster'][component]['host'] ||
        get_ip(component_node)
    end

    def get_supermarket_attribute(attr)
      @supermarket ||= begin
        supermarket_file = File.read("#{cluster_data_dir}/supermarket.json")
        JSON.parse(supermarket_file)
      end
      @supermarket[attr]
    end

    def chef_server_url
      "https://#{chef_server_fqdn}/organizations/#{node['delivery-cluster']['chef-server']['organization']}"
    end

    def activate_splunk
      FileUtils.touch(splunk_lock_file)
    end

    def splunk_enabled?
      File.exist?(splunk_lock_file)
    end

    def activate_analytics
      FileUtils.touch(analytics_lock_file)
    end

    def activate_supermarket
      FileUtils.touch(supermarket_lock_file)
    end

    def analytics_enabled?
      File.exist?(analytics_lock_file)
    end

    def supermarket_enabled?
      File.exist?(supermarket_lock_file)
    end

    def analytics_server_attributes
      return {} unless analytics_enabled?
      {
        'chef-server-12' => {
          'analytics' => {
            'fqdn' => analytics_server_fqdn
          }
        }
      }
    end

    def supermarket_server_attributes
      return {} unless supermarket_enabled?
      {
        'chef-server-12' => {
          'supermarket' => {
            'fqdn' => supermarket_server_fqdn
          }
        }
      }
    end

    def chef_server_attributes
      @chef_server_attributes = {
        'chef-server-12' => {
          'delivery' => { 'organization' => node['delivery-cluster']['chef-server']['organization'] },
          'api_fqdn' => chef_server_fqdn,
          'store_keys_databag' => false,
          'plugin' => {
            'opscode-reporting' => node['delivery-cluster']['chef-server']['enable-reporting']
          }
        }
      }
      @chef_server_attributes = Chef::Mixin::DeepMerge.hash_only_merge(@chef_server_attributes, analytics_server_attributes)
      @chef_server_attributes = Chef::Mixin::DeepMerge.hash_only_merge(@chef_server_attributes, supermarket_server_attributes)
      @chef_server_attributes
    end

    def chef_server_config
      {
        chef_server_url: chef_server_url,
        options: {
          client_name: 'delivery',
          signing_key_filename: "#{cluster_data_dir}/delivery.pem"
        }
      }
    end

    def delivery_server_attributes
      # If we want to pull down the packages from Chef Artifactory
      if node['delivery-cluster']['delivery']['artifactory']
        artifact = delivery_artifact
        node.set['delivery-cluster']['delivery']['version']   = artifact['version']
        node.set['delivery-cluster']['delivery']['artifact']  = artifact['artifact']
        node.set['delivery-cluster']['delivery']['checksum']  = artifact['checksum']
      end

      # Configuring the chef-server url for delivery
      node.set['delivery-cluster']['delivery']['chef_server'] = chef_server_url unless node['delivery-cluster']['delivery']['chef_server']

      # Ensure we havea Delivery FQDN
      node.set['delivery-cluster']['delivery']['fqdn'] = delivery_server_fqdn unless node['delivery-cluster']['delivery']['fqdn']

      { 'delivery-cluster' => node['delivery-cluster'] }
    end

    def builders_attributes
      builders_attributes = {}

      # Add cli attributes if they exists.
      builders_attributes['delivery_build'] = { 'delivery-cli' => node['delivery-cluster']['builders']['delivery-cli'] } unless node['delivery-cluster']['builders']['delivery-cli'].empty?

      builders_attributes
    end

    def delivery_enterprise_cmd
      # We have introduced an additional constrain to the enterprise_ctl
      # command that require to specify --ssh-pub-key-file param starting
      # from the Delivery Version 0.2.52
      cmd = <<-CMD.gsub(/\s+/, ' ').strip!
        #{delivery_ctl} list-enterprises | grep -w ^#{node['delivery-cluster']['delivery']['enterprise']};
        [ $? -ne 0 ] && #{delivery_ctl} create-enterprise #{node['delivery-cluster']['delivery']['enterprise']}
      CMD
      if node['delivery-cluster']['delivery']['version'] == 'latest' ||
         Gem::Version.new(node['delivery-cluster']['delivery']['version']) > Gem::Version.new('0.2.52')
        cmd << ' --ssh-pub-key-file=/etc/delivery/builder_key.pub'
      end
      cmd << " > /tmp/#{node['delivery-cluster']['delivery']['enterprise']}.creds || echo 1"
    end

    def delivery_artifact
      # We will get the Delivery Package from artifactory (Require Chef VPN)
      #
      # Get the latest artifact:
      # => artifact = get_delivery_artifact('latest', 'redhat', '6.5')
      #
      # Get specific artifact:
      # => artifact = get_delivery_artifact('0.2.21', 'ubuntu', '12.04', '/var/tmp')
      #
      @delivery_artifact ||= begin
        artifact = get_delivery_artifact(
          node['delivery-cluster']['delivery']['version'],
          component_node('delivery')['platform'],
          component_node('delivery')['platform_version'],
          node['delivery-cluster']['delivery']['pass-through'] ? nil : cluster_data_dir
        )

        delivery_artifact = {
          'version'  => artifact['version'],
          'checksum' => artifact['checksum']
        }
        # Upload Artifact to Delivery Server only if we have donwloaded the artifact
        if artifact['local_path']
          machine_file = Chef::Resource::MachineFile.new("/var/tmp/#{artifact['name']}", run_context)
          machine_file.chef_server(chef_server_config)
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

    # Upload a specific cookbook to our chef-server
    def upload_cookbook(cookbook)
      execute "Upload Cookbook => #{cookbook}" do
        command "knife cookbook upload #{cookbook} --cookbook-path #{Chef::Config[:cookbook_path]}"
        environment(
          'KNIFE_HOME' => cluster_data_dir
        )
        not_if "knife cookbook show #{cookbook}"
      end
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
end

Chef::Recipe.send(:include, DeliveryCluster::Helper)
Chef::Resource.send(:include, DeliveryCluster::Helper)
Chef::Provider.send(:include, DeliveryCluster::Helper)
