#
# Cookbook Name:: delivery-cluster
# Recipe:: _helper
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

module DeliveryCluster
  module Helper
    def current_dir
      Chef::Config.chef_repo_path
    end

    def tmp_infra_dir
      File.join(Chef::Config[:file_cache_path], 'infra')
    end

    def get_aws_ip(n)
      if node['delivery_cluster']['aws']['use_private_ip_for_ssh']
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

    def builder_key
      if File.exists?("#{tmp_infra_dir}/builder_key")
        OpenSSL::PKey::RSA.new(File.read("#{tmp_infra_dir}/builder_key"))
      else
        OpenSSL::PKey::RSA.generate(2048)
      end
    end
  end
end

Chef::Recipe.send(:include, DeliveryCluster::Helper)
Chef::Resource.send(:include, DeliveryCluster::Helper)
