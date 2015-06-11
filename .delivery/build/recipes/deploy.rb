#
# Cookbook Name:: build
# Recipe:: deploy
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
template "Update Environment Template" do
  path File.join(path, "environments/#{environment}.json")
  source 'environment.json.erb'
  variables(
    :delivery_license => "#{cache}/delivery.license",
    :delivery_version => "latest"
    :environment => environment
  )
end

execute "Upgrade Delivery Cluster To Latest" do
  cwd path
  command <<-EOF
    chef exec bundle exec chef-client -z -o delivery-cluster::setup -E #{environment} -l auto > #{cache}/delivery-cluster-setup.log
    cp -r clients nodes .chef/delivery-cluster-data-* .chef/trusted_certs /var/opt/delivery/workspace/delivery-cluster-aws-cache/
  EOF
  environment ({
    'AWS_CONFIG_FILE' => "#{cache}/.aws/config"
  })
end
