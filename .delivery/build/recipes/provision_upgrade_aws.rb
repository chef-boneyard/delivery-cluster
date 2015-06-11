#
# Cookbook Name:: build
# Recipe:: provision_extra_case
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
chef_gem "chef-rewind"
require 'chef/rewind'

environment = node['delivery']['change']['stage']

execute "Restore Provisioning Bits" do
  cwd path
  command <<-EOF
    mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/clients clients
    mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/nodes nodes
    mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/trusted_certs .chef/.
    mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/delivery-cluster-data-* .chef/.
  EOF
  environment ({
    'AWS_CONFIG_FILE' => "#{cache}/.aws/config"
  })
  only_if do ::File.exists?('var/opt/delivery/workspace/delivery-cluster-aws-cache/nodes') end
end

include_recipe "build::provision_clean_aws"

unwind "execute[Create Environment Template]"

rewind "template[Create Environment Template]" do
  variables(
    :delivery_license => "#{cache}/delivery.license",
    :delivery_version => "0.3.73",
    :environment => environment
  )
end
