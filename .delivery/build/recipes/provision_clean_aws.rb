#
# Cookbook Name:: build
# Recipe:: provision_clean_aws
#
# Copyright (c) 2015 The Authors, All Rights Reserved.
delivery_secrets = get_project_secrets
cluster_name     = "#{node['delivery']['change']['stage']}_#{node['delivery']['change']['pipeline']}"
path             = node['delivery']['workspace']['repo']
cache            = node['delivery']['workspace']['cache']

ssh_private_key_path =  File.join(cache, '.ssh', "chef-delivery-cluster")
ssh_public_key_path  =  File.join(cache, '.ssh', "chef-delivery-cluster.pub")

directory File.join(cache, '.ssh')
directory File.join(cache, '.aws')
directory File.join(path, 'environments')

file ssh_private_key_path do
  content delivery_secrets['private_key']
  owner node['delivery_builder']['build_user']
  group node['delivery_builder']['build_user']
  mode '0600'
end

file ssh_public_key_path do
  content delivery_secrets['public_key']
  owner node['delivery_builder']['build_user']
  group node['delivery_builder']['build_user']
  mode '0644'
end

template "Create Environment Template" do
  path File.join(path, "environments/#{cluster_name}.json")
  source 'environment.json.erb'
  variables(
    :delivery_license => "#{cache}/delivery.license",
    :delivery_version => "latest",
    :cluster_name => cluster_name
  )
end

template File.join(cache, '.aws/config') do
  source 'aws-config.erb'
  variables(
    :aws_access_key_id => delivery_secrets['access_key_id'],
    :aws_secret_access_key => delivery_secrets['secret_access_key'],
    :region => delivery_secrets['region']
  )
end

s3_file File.join(cache, 'delivery.license') do
  remote_path "licenses/delivery-internal.license"
  bucket "delivery-packages"
  aws_access_key_id delivery_secrets['access_key_id']
  aws_secret_access_key delivery_secrets['secret_access_key']
  action :create
end

# Assemble your gem dependencies
execute "chef exec bundle install" do
  cwd path
end

# Assemble your cookbook dependencies
execute "chef exec bundle exec berks vendor cookbooks" do
  cwd path
end

# Destroy the old Delivery Cluster
#
# We are using a temporal cache directory to save the state of our cluster.
# HERE: we are moving the data back to the repository path before we trigger
# the destroy task
#
# TODO: We need to figure a better way to do this
execute "Destroy the old Delivery Cluster" do
  cwd path
  command <<-EOF
    mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/clients clients
    mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/nodes nodes
    mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/trusted_certs .chef/.
    mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/delivery-cluster-data-* .chef/.
    chef exec bundle exec chef-client -z -o delivery-cluster::destroy_all -E #{cluster_name} > #{cache}/delivery-cluster-destroy-all.log
  EOF
  environment ({
    'AWS_CONFIG_FILE' => "#{cache}/.aws/config"
  })
  only_if do ::File.exists?('var/opt/delivery/workspace/delivery-cluster-aws-cache/nodes') end
end

# Create a new Delivery Cluster
#
# We are using a temporal cache directory to save the state of our cluster
# HERE: we are copying the data after we create the Delivery Cluster
#
# TODO: We need to figure a better way to do this
execute "Create a new Delivery Cluster" do
  cwd path
  command <<-EOF
    chef exec bundle exec chef-client -z -o delivery-cluster::setup -E #{cluster_name} -l auto > #{cache}/delivery-cluster-setup.log
    cp -r clients nodes .chef/delivery-cluster-data-* .chef/trusted_certs /var/opt/delivery/workspace/delivery-cluster-aws-cache/
  EOF
  environment ({
    'AWS_CONFIG_FILE' => "#{cache}/.aws/config"
  })
end

# Print the Delivery Credentials
ruby_block 'print-delivery-credentials' do
  block do
    puts File.read(File.join(path, ".chef/delivery-cluster-data-#{cluster_name}/#{cluster_name}.creds"))
  end
end

ruby_block "Get Services" do
  block do
    list_services = Mixlib::ShellOut.new("rake info:list_core_services",
                                         :cwd => node['delivery']['workspace']['repo'])

    list_services.run_command

    if list_services.stdout
      node.run_state['delivery'] ||= {}
      node.run_state['delivery']['stage'] ||= {}
      node.run_state['delivery']['stage']['data'] ||= {}
      node.run_state['delivery']['stage']['data']['cluster_details'] ||= {}

      previous_line = nil
      list_services.stdout.each_line do |line|
        if previous_line =~ /^delivery-server\S+:$/
          ipaddress = line.match(/^  ipaddress: (\S+)$/)[1]
          node.run_state['delivery']['stage']['data']['cluster_details']['delivery'] ||= {}
          node.run_state['delivery']['stage']['data']['cluster_details']['delivery']['url'] = ipaddress
        elsif previous_line =~ /^build-node\S+:/
          ipaddress = line.match(/^  ipaddress: (\S+)$/)[1]
          node.run_state['delivery']['stage']['data']['cluster_details']['build_nodes'] ||= []
          node.run_state['delivery']['stage']['data']['cluster_details']['build_nodes'] << ipaddress
        elsif line =~ /^chef_server_url.*$/
          ipaddress = URI(line.match(/^chef_server_url\s+'(\S+)'$/)[1]).host
          node.run_state['delivery']['stage']['data']['build_nodes']['chef_server'] ||= {}
          node.run_state['delivery']['stage']['data']['build_nodes']['chef_server']['url'] = ipaddress
        end
        previous_line = line
      end
    end
  end
end

delivery_stage_db
