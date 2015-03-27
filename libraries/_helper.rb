#
# Cookbook Name:: delivery-cluster
# Recipe:: _helper
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

require 'openssl'
require 'fileutils'
require 'securerandom'

module DeliveryCluster
  module Helper
    def current_dir
      Chef::Config.chef_repo_path
    end

    def cluster_data_dir
      File.join(current_dir, '.chef', 'delivery-cluster-data')
    end

    # We will return the right IP to use depending wheter we need to
    # use the Private IP or the Public IP
    def get_aws_ip(n)
      if node['delivery-cluster']['aws']['use_private_ip_for_ssh']
        n['ec2']['local_ipv4']
      else
        n['ec2']['public_ipv4']
      end
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

    def delivery_builder_hostname(index)
      unless node['delivery-cluster']['builders']['hostname_prefix']
        node.set['delivery-cluster']['builders']['hostname_prefix'] = "build-node-#{delivery_cluster_id}"
      end

      "#{node['delivery-cluster']['builders']['hostname_prefix']}-#{index}"
    end

    def builder_private_key
      File.read(File.join(cluster_data_dir, "builder_key"))
    end

    def builder_run_list
      @builder_run_list ||= begin
        base_builder_run_list = %w( recipe[push-jobs] recipe[delivery_build] )
        base_builder_run_list + node['delivery-cluster']['builders']['additional_run_list']
      end
    end

    # Generate or load an existing encrypted data bag secret
    def encrypted_data_bag_secret
      if File.exists?("#{cluster_data_dir}/encrypted_data_bag_secret")
        File.read("#{cluster_data_dir}/encrypted_data_bag_secret")
      else
        # Ruby's `SecureRandom` module uses OpenSSL under the covers
        SecureRandom.base64(512)
      end
    end

    def chef_server_ip
      @@chef_server_ip ||= begin
        chef_server_node = Chef::Node.load(chef_server_hostname)
        chef_server_ip   = get_aws_ip(chef_server_node)
        Chef::Log.info("Your Chef Server Public/Private IP is => #{chef_server_ip}")
        chef_server_ip
      end
    end

    def analytics_lock_file
      "#{cluster_data_dir}/analytics"
    end

    def splunk_lock_file
      "#{cluster_data_dir}/splunk"
    end

    def analytics_server_node
      @@analytics_server_node ||= begin
        Chef::REST.new(
          chef_server_config[:chef_server_url],
          chef_server_config[:options][:client_name],
          chef_server_config[:options][:signing_key_filename]
        ).get_rest("nodes/#{analytics_server_hostname}")
      end
    end

    def analytics_server_ip
      @@analytics_server_ip ||= begin
        analytics_server_ip   = get_aws_ip(analytics_server_node)
        Chef::Log.info("Your Analytics Server Public/Private IP is => #{analytics_server_ip}")
        analytics_server_ip
      end
    end

    def chef_server_url
      "https://#{chef_server_ip}/organizations/#{node['delivery-cluster']['chef-server']['organization']}"
    end

    def activate_splunk
      FileUtils.touch(splunk_lock_file)
    end

    def is_splunk_enabled?
      File.exist?(splunk_lock_file)
    end

    def activate_analytics
      FileUtils.touch(analytics_lock_file)
    end

    def is_analytics_enabled?
      File.exist?(analytics_lock_file)
    end

    def analytics_server_attributes
      return {} unless is_analytics_enabled?
      {
        'analytics' => {
          'fqdn' => analytics_server_ip
        }
      }
    end

    def chef_server_attributes
      {
        'chef-server-12' => {
          'delivery' => { 'organization' => node['delivery-cluster']['chef-server']['organization'] },
          'api_fqdn' => chef_server_ip,
          'store_keys_databag' => false
        }.merge(analytics_server_attributes)
      }
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
      @@delivery_server_node ||= begin
        Chef::REST.new(
          chef_server_config[:chef_server_url],
          chef_server_config[:options][:client_name],
          chef_server_config[:options][:signing_key_filename]
        ).get_rest("nodes/#{delivery_server_hostname}")
      end
    end

    def delivery_server_ip
      @@delivery_server_ip ||= begin
        delivery_server_ip   = get_aws_ip(delivery_server_node)
        Chef::Log.info("Your Delivery Server Public/Private IP is => #{delivery_server_ip}")
        delivery_server_ip
      end
    end

    def delivery_server_attributes
      delivery_attributes = {
        'applications' => {
          'delivery' => delivery_server_version
        },
        'delivery' => {
          'chef_server' => chef_server_url,
          'fqdn'        => node['delivery-cluster']['delivery']['fqdn'] || delivery_server_ip
        }
      }

      # Add LDAP config if it exist
      delivery_attributes['delivery']['ldap'] = node['delivery-cluster']['delivery']['ldap'] unless node['delivery-cluster']['delivery']['ldap'].empty?

      delivery_attributes
    end

    def delivery_enterprise_cmd
      # We have introduced an additional constrain to the enterprise_ctl
      # command that require to specify --ssh-pub-key-file param starting
      # from the Delivery Version 0.2.52
      cmd = <<-CMD.gsub(/\s+/, " ").strip!
        #{delivery_ctl} list-enterprises | grep -w ^#{node['delivery-cluster']['delivery']['enterprise']};
        [ $? -ne 0 ] && #{delivery_ctl} create-enterprise #{node['delivery-cluster']['delivery']['enterprise']}
      CMD
      cmd << ' --ssh-pub-key-file=/etc/delivery/builder_key.pub' unless Gem::Version.new(delivery_server_version) < Gem::Version.new('0.2.52')
      cmd << " > /tmp/#{node['delivery-cluster']['delivery']['enterprise']}.creds || echo 1"
    end

    def delivery_artifact
      # If we don't have the artifact, we will get it from artifactory
      # We will need VPN to do so. Or other way could be to upload it
      # to S3 bucket automatically
      #
      # Get the latest artifact:
      # => artifact = get_delivery_artifact('latest', 'redhat', '6.5')
      #
      # Get specific artifact:
      # => artifact = get_delivery_artifact('0.2.21', 'ubuntu', '12.04', '/var/tmp')
      #
      if node['delivery-cluster']['delivery'][delivery_server_node['platform_family']] && node['delivery-cluster']['delivery']['version'] != 'latest'
        # We use the provided artifact
        delivery_artifact = {
          delivery_server_node['platform_family'] => {
            "artifact" => node['delivery-cluster']['delivery'][delivery_server_node['platform_family']]['artifact'],
            "checksum" => node['delivery-cluster']['delivery'][delivery_server_node['platform_family']]['checksum']
          }
        }
      else
        # We will get it from artifactory
        artifact = get_delivery_artifact(
                      node['delivery-cluster']['delivery']['version'],
                      delivery_server_node['platform'],
                      delivery_server_node['platform_version'],
                      node['delivery-cluster']['delivery']['pass-through'] ? nil : cluster_data_dir
                    )

        delivery_artifact = {
          delivery_server_node['platform_family'] => {
            "checksum" => artifact['checksum']
          }
        }
        # Upload Artifact to Delivery Server only if we have donwloaded the artifact
        if artifact['local_path']
          machine_file = Chef::Resource::MachineFile.new("/var/tmp/#{artifact['name']}", run_context)
          machine_file.chef_server(chef_server_config)
          machine_file.machine(node['delivery-cluster']['delivery']['hostname'])
          machine_file.local_path(artifact['local_path'])
          machine_file.run_action(:upload)

          delivery_artifact[delivery_server_node['platform_family']]['artifact'] = "/var/tmp/#{artifact['name']}"
        else
          delivery_artifact[delivery_server_node['platform_family']]['artifact'] = artifact['uri']
        end
      end

      delivery_artifact
    end

    def delivery_server_version
      @delivery_server_version ||= begin
        if node['delivery-cluster']['delivery'][delivery_server_node['platform_family']] && node['delivery-cluster']['delivery']['version'] != 'latest'
          node['delivery-cluster']['delivery']['version']
        else
          artifact = get_delivery_artifact(
                        node['delivery-cluster']['delivery']['version'],
                        delivery_server_node['platform'],
                        delivery_server_node['platform_version'],
                        node['delivery-cluster']['delivery']['pass-through'] ? nil : cluster_data_dir
                      )
          artifact['version']
        end
      end
    end
  end
end

Chef::Recipe.send(:include, DeliveryCluster::Helper)
Chef::Resource.send(:include, DeliveryCluster::Helper)
