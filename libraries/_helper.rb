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
      @current_dir ||= Chef::Config.chef_repo_path
    end

    def tmp_infra_dir
      @tmp_infra_dir ||= File.join(current_dir, "infra/tmp")
    end

    def dot_chef_dir
      @dot_chef_dir ||= File.join(current_dir, '.chef')
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
  end
end

Chef::Recipe.send(:include, DeliveryCluster::Helper)
Chef::Resource.send(:include, DeliveryCluster::Helper)
