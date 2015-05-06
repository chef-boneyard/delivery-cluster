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
    def provisioning
      @provisioning ||= DeliveryCluster::Provisioning.for_driver(node['delivery-cluster']['driver'], node)
    end

    def current_dir
      Chef::Config.chef_repo_path
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
      unless node['delivery-cluster']['splunk']['hostname']
        node.set['delivery-cluster']['splunk']['hostname'] = "splunk-server-#{delivery_cluster_id}"
      end

      node['delivery-cluster']['splunk']['hostname']
    end

    def chef_server_hostname
      unless node['delivery-cluster']['chef-server']['hostname']
        node.set['delivery-cluster']['chef-server']['hostname'] = "chef-server-#{delivery_cluster_id}"
      end

      node['delivery-cluster']['chef-server']['hostname']
    end

    def delivery_server_hostname
      unless node['delivery-cluster']['delivery']['hostname']
        node.set['delivery-cluster']['delivery']['hostname'] = "delivery-server-#{delivery_cluster_id}"
      end

      node['delivery-cluster']['delivery']['hostname']
    end

    def analytics_server_hostname
      unless node['delivery-cluster']['analytics']['hostname']
        node.set['delivery-cluster']['analytics']['hostname'] = "analytics-server-#{delivery_cluster_id}"
      end

      node['delivery-cluster']['analytics']['hostname']
    end

    def supermarket_server_hostname
      unless node['delivery-cluster']['supermarket']['hostname']
        node.set['delivery-cluster']['supermarket']['hostname'] = "supermarket-server-#{delivery_cluster_id}"
      end

      node['delivery-cluster']['supermarket']['hostname']
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

    def chef_server_fqdn
      @chef_server_fqdn ||= begin
        chef_server_node = Chef::Node.load(chef_server_hostname)
        chef_server_fqdn = get_ip(chef_server_node)
        Chef::Log.info("Your Chef Server Public/Private IP is => #{chef_server_fqdn}")
        node['delivery-cluster']['chef-server']['fqdn'] ||
        node['delivery-cluster']['chef-server']['host'] ||
        chef_server_fqdn
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

    def analytics_server_node
      @analytics_server_node ||= begin
        Chef::REST.new(
          chef_server_config[:chef_server_url],
          chef_server_config[:options][:client_name],
          chef_server_config[:options][:signing_key_filename]
        ).get_rest("nodes/#{analytics_server_hostname}")
      end
    end

    def supermarket_server_node
      @supermarket_server_node ||= begin
        Chef::REST.new(
          chef_server_config[:chef_server_url],
          chef_server_config[:options][:client_name],
          chef_server_config[:options][:signing_key_filename]
        ).get_rest("nodes/#{supermarket_server_hostname}")
      end
    end

    def analytics_server_fqdn
      @analytics_server_fqdn ||= begin
        analytics_server_fqdn  = get_ip(analytics_server_node)
        Chef::Log.info("Your Analytics Server Public/Private IP is => #{analytics_server_fqdn}")
        node['delivery-cluster']['analytics']['fqdn'] ||
        node['delivery-cluster']['analytics']['host'] ||
        analytics_server_fqdn
      end
    end

    def supermarket_server_fqdn
      @supermarket_server_fqdn ||= begin
        supermarket_server_fqdn  = get_ip(supermarket_server_node)
        Chef::Log.info("Your Supermarket Server Public/Private IP is => #{supermarket_server_fqdn}")
        node['delivery-cluster']['supermarket']['fqdn'] ||
        node['delivery-cluster']['supermarket']['host'] ||
        supermarket_server_fqdn
      end
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
            'opscode-reporting' => false
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

    def delivery_server_node
      @delivery_server_node ||= begin
        Chef::REST.new(
          chef_server_config[:chef_server_url],
          chef_server_config[:options][:client_name],
          chef_server_config[:options][:signing_key_filename]
        ).get_rest("nodes/#{delivery_server_hostname}")
      end
    end

    def delivery_server_fqdn
      @delivery_server_fqdn ||= begin
        delivery_server_fqdn  = get_ip(delivery_server_node)
        Chef::Log.info("Your Delivery Server Public/Private IP is => #{delivery_server_fqdn}")
        node['delivery-cluster']['delivery']['fqdn'] ||
        node['delivery-cluster']['delivery']['host'] ||
        delivery_server_fqdn
      end
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
                      delivery_server_node['platform'],
                      delivery_server_node['platform_version'],
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
