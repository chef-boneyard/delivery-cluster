#
# Cookbook Name:: delivery-cluster
# Library:: aws
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

module DeliveryCluster
  module Provisioning

    # AWS class for AWS Provisioning Driver
    #
    # Specify all the methods a Provisioning Driver should implement
    # @author Salim Afiune <afiune@chef.io>
    class Aws < DeliveryCluster::Provisioning::Base

      require 'chef/provisioning/aws_driver'

      attr_accessor :flavor
      attr_accessor :key_name
      attr_accessor :image_id
      attr_accessor :subnet_id
      attr_accessor :ssh_username
      attr_accessor :security_group_ids
      attr_accessor :use_private_ip_for_ssh

      # Create a new Provisioning Driver Abstraction
      #
      # @param node [Chef::Node]
      def initialize(node)
        raise "Aws Attributes not implemented (node['delivery-cluster']['aws'])" unless node['delivery-cluster']['aws']
        @flavor                 = node['delivery-cluster']['aws']['flavor'] if node['delivery-cluster']['aws']['flavor']
        @key_name               = node['delivery-cluster']['aws']['key_name'] if node['delivery-cluster']['aws']['key_name']
        @image_id               = node['delivery-cluster']['aws']['image_id'] if node['delivery-cluster']['aws']['image_id']
        @subnet_id              = node['delivery-cluster']['aws']['subnet_id'] if node['delivery-cluster']['aws']['subnet_id']
        @ssh_username           = node['delivery-cluster']['aws']['ssh_username'] if node['delivery-cluster']['aws']['ssh_username']
        @security_group_ids     = node['delivery-cluster']['aws']['security_group_ids'] if node['delivery-cluster']['aws']['security_group_ids']
        @use_private_ip_for_ssh = false
        @use_private_ip_for_ssh = node['delivery-cluster']['aws']['use_private_ip_for_ssh'] if node['delivery-cluster']['aws']['use_private_ip_for_ssh']
      end

      # Return the machine options to use.
      #
      # @return [Hash] the machine_options for the specific driver
      def machine_options
        {
          bootstrap_options: {
            instance_type:      @flavor,
            key_name:           @key_name,
            subnet_id:          @subnet_id,
            security_group_ids: @security_group_ids,
          },
          ssh_username:           @ssh_username,
          image_id:               @image_id,
          use_private_ip_for_ssh: @use_private_ip_for_ssh
        }
      end

      # Return the Provisioning Driver Name.
      #
      # @return [String] the provisioning driver name
      def driver
        'aws'
      end
      # Return the ipaddress from the machine.
      #
      # @param node [Chef::Node]
      # @return [String] an ipaddress
      def ipaddress(node, use_private_ip_for_ssh = false)
        use_private_ip_for_ssh ? node['ec2']['local_ipv4'] : node['ec2']['public_ipv4']
      end

    end
  end
end
