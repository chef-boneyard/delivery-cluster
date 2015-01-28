#
# Cookbook Name:: delivery-cluster
# Recipe:: _helper
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

require 'openssl'
require 'securerandom'

module DeliveryCluster
  module Helper
    def current_dir
      Chef::Config.chef_repo_path
    end

    def tmp_infra_dir
      File.join(Chef::Config[:file_cache_path], 'infra')
    end

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

    def delivery_cluster_id
      unless node['delivery-cluster']['id']
        node.set['delivery-cluster']['id'] = "test-#{SecureRandom.hex(3)}"
        node.save
      end

      node['delivery-cluster']['id']
    end

    def chef_server_hostname
      unless node['delivery-cluster']['chef-server']['hostname']
        node.set['delivery-cluster']['chef-server']['hostname'] = "chef-server-#{delivery_cluster_id}"
        node.save
      end

      node['delivery-cluster']['chef-server']['hostname']
    end

    def delivery_server_hostname
      unless node['delivery-cluster']['delivery']['hostname']
        node.set['delivery-cluster']['delivery']['hostname'] = "delivery-server-#{delivery_cluster_id}"
        node.save
      end

      node['delivery-cluster']['delivery']['hostname']
    end

    def delivery_builder_hostname(index)
      unless node['delivery-cluster']['builders']['hostname_prefix']
        node.set['delivery-cluster']['builders']['hostname_prefix'] = "build-node-#{delivery_cluster_id}"
        node.save
      end

      "#{node['delivery-cluster']['builders']['hostname_prefix']}-#{index}"
    end

    # Generate or load an existing RSA keypair
    def builder_key
      if File.exists?("#{tmp_infra_dir}/builder_key")
        OpenSSL::PKey::RSA.new(File.read("#{tmp_infra_dir}/builder_key"))
      else
        OpenSSL::PKey::RSA.generate(2048)
      end
    end

    # Generate or load an existing encrypted data bag secret
    def encrypted_data_bag_secret
      if File.exists?("#{tmp_infra_dir}/encrypted_data_bag_secret")
        File.read("#{tmp_infra_dir}/encrypted_data_bag_secret")
      else
        # Ruby's `SecureRandom` module uses OpenSSL under the covers
        SecureRandom.base64(512)
      end
    end

    def chef_server_ip
      chef_server_node = Chef::Node.load(node['delivery-cluster']['chef-server']['hostname'])
      chef_server_ip   = get_aws_ip(chef_server_node)
      Chef::Log.info("Your Chef Server Public IP is => #{chef_server_ip}")
      chef_server_ip
    end

    def chef_server_url
      "https://#{chef_server_ip}/organizations/#{node['delivery-cluster']['chef-server']['organization']}"
    end

    def chef_server_attributes
      {
        'chef-server-12' => {
          'delivery' => { 'organization' => node['delivery-cluster']['chef-server']['organization'] },
          'api_fqdn' => chef_server_ip,
          'store_keys_databag' => false
        }
      }
    end

    def delivery_server_ip
      delivery_server_node = Chef::Node.load(node['delivery-cluster']['delivery']['hostname'])
      delivery_server_ip   = get_aws_ip(delivery_server_node)
      Chef::Log.info("Your Delivery Server Public IP is => #{deliv_ip}")
      delivery_server_ip
    end

    def delivery_attributes
      delivery_attributes = {
        'applications' => {
          'delivery' => deliv_version
        },
        'delivery' => {
          'chef_server' => chef_server_url,
          'fqdn'        => deliv_ip
        }
      }

      # Add LDAP config if it exist
      delivery_attributes['delivery']['ldap'] = node['delivery_cluster']['delivery']['ldap'] unless node['delivery_cluster']['delivery']['ldap'].empty?

      delivery_attributes
    end

    def delivery_artifact
      delivery_server_node = Chef::Node.load(node['delivery-cluster']['delivery']['hostname'])

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
        artifact = get_delivery_artifact(node['delivery-cluster']['delivery']['version'], delivery_server_node['platform'], delivery_server_node['platform_version'], tmp_infra_dir)

        # Upload Artifact to Delivery Server
        machine_file "/var/tmp/#{artifact['name']}" do
          machine node['delivery-cluster']['delivery']['hostname']
          local_path  artifact['local_path']
          action :upload
        end

        delivery_artifact = {
          delivery_server_node['platform_family'] => {
            "artifact" => "/var/tmp/#{artifact['name']}",
            "checksum" => artifact['checksum']
          }
        }
      end

      delivery_artifact
    end

    def delivery_server_version
      @delivery_server_version ||= begin
        delivery_server_node = Chef::Node.load(node['delivery-cluster']['delivery']['hostname'])

        if node['delivery-cluster']['delivery'][delivery_server_node['platform_family']] && node['delivery-cluster']['delivery']['version'] != 'latest'
          node['delivery-cluster']['delivery']['version']
        else
          artifact = get_delivery_artifact(node['delivery-cluster']['delivery']['version'], delivery_server_node['platform'], delivery_server_node['platform_version'], tmp_infra_dir)
          artifact['version']
        end
      end
    end
  end
end

Chef::Recipe.send(:include, DeliveryCluster::Helper)
Chef::Resource.send(:include, DeliveryCluster::Helper)
