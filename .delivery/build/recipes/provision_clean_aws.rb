#
# Cookbook Name:: build
# Recipe:: provision_clean_aws
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

delivery_secrets = get_project_secrets
cluster_name     = "#{node['delivery']['change']['stage']}_#{node['delivery']['change']['pipeline']}"
root             = node['delivery']['workspace']['root']
path             = node['delivery']['workspace']['repo']
cache            = node['delivery']['workspace']['cache']

ssh_private_key_path =  File.join(cache, '.ssh', 'chef-delivery-cluster')
ssh_public_key_path  =  File.join(cache, '.ssh', 'chef-delivery-cluster.pub')

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

template 'Create Environment Template' do
  path File.join(path, "environments/#{cluster_name}.json")
  source 'aws-clean-env.json.erb'
  variables(
    :delivery_license => "#{cache}/delivery.license",
    :delivery_version => 'latest',
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
  remote_path 'licenses/delivery-internal.license'
  bucket 'delivery-packages'
  aws_access_key_id delivery_secrets['access_key_id']
  aws_secret_access_key delivery_secrets['secret_access_key']
  action :create
end

# Install all the prerequisites on the build-node
#
# Here we are assambling our gem and cookbook dependencies, when this
# command runs, the delivery-cluster cookbook converts into a monolitic
# chef-repo that has cookbooks/ environments/ nodes/ clients/ etc.
# The gem deps will be installed on a `cache` directory
ruby_block 'Setup Prerequisites' do
  block do
    shell_out!(
      "rake setup:prerequisites",
      :environment => { 'CHEF_ENV' => cluster_name },
      :live_stream => STDOUT,
      :cwd => path
    )
  end
end

# Destroy the old Delivery Cluster
#
# The current clycle for this cookbook is to destroy the old cluster we
# have running and then create a brand new one from scratch.
# For now are using a temporal cache directory outside of the workspace
# to save the state of our clusters and don't loose control, therefore
# the first thing we do is move the data back to the repository path
# before we trigger the destroy_all rake task.
#
# TODO: We need to figure a better way to do this
ruby_block 'Destroy old Delivery Cluster' do
  block do
    restore_cluster_data(root, node, delivery_secrets)
    shell_out(
      'rake destroy:all',
      :cwd => path,
      :timeout => cluster_timeout,
      :live_stream => STDOUT,
      :environment => {
        'CHEF_ENV' => cluster_name,
        'AWS_CONFIG_FILE' => "#{cache}/.aws/config"
      }
    )
  end
end

# Create a new Delivery Cluster
#
# Once we have deleted our old cluster it is time to build a new one from
# scratch. At the moment there are many problems in chef-provisioning that
# causes delivery-cluster to fail randomly, therefor instead of failing
# immediatelly we will try to run the automation multiple times (5) until
# we succeed. Every time that the cluster setup fails we will display the
# error to keep records and to be able to create the pertinent issues and
# get them fixed.
# In the future this loop should be deleted and delivery-cluster should
# work without the need of re-run multiple times.
#
# After we completed or failed to setup the new cluster we must backup the
# critical data directories to be able to manipulate the cluster on further
# changes and pipelines.
#
# TODO: We need to figure a better way to do this
ruby_block 'Create a new Delivery Cluster' do
  block do
    times = 0
    until 5 < times
      setup_cluster = shell_out(
                        'rake setup:cluster',
                        :cwd => path,
                        :timeout => cluster_timeout,
                        :live_stream => STDOUT,
                        :environment => {
                          'CHEF_ENV' => cluster_name,
                          'AWS_CONFIG_FILE' => "#{cache}/.aws/config"
                        }
                      )

      # If we completed the cluster setup, break the loop
      break if setup_cluster.exitstatus.eql?(0)

      # Printing the error and exitcode
      puts "Command exited with code: #{setup_cluster.exitstatus}"
      puts "ERROR MESSAGE: #{setup_cluster.stderr}"

      # Lets try it one more time
      times += 1
      puts "Re-running 'rake setup:cluster' (#{times}/5)"
    end

    # Finally we backup the cluster data
    backup_cluster_data(root, node, delivery_secrets)
  end
end

# Print the Delivery Credentials
ruby_block 'print-delivery-credentials' do
  block do
    shell_out!(
      'rake info:delivery_creds',
      :cwd => path,
      :live_stream => STDOUT
    )
  end
end

ruby_block 'Get Services' do
  block do
    list_services = shell_out(
                      'rake info:list_core_services',
                      :cwd => path,
                      :live_stream => STDOUT
                    )

    # Print Services
    puts list_services.stdout

    if list_services.stdout
      node.run_state['delivery'] = {
        'stage' => {
          'data' => {
            'cluster_details' => {
              'delivery' => {},
              'build_nodes' => [],
              'supermarket_server' => {},
              'chef_server' => {}
            }
          }
        }
      }

      previous_line = nil
      list_services.stdout.each_line do |line|
        case previous_line
        when /^delivery-server\S+:$/
          ipaddress = line.match(/^\s+ipaddress: (\S+)$/)[1]
          node.run_state['delivery']['stage']['data']['cluster_details']['delivery']['url'] = ipaddress
        when /^build-node\S+:/
          ipaddress = line.match(/^\s+ipaddress: (\S+)$/)[1]
          node.run_state['delivery']['stage']['data']['cluster_details']['build_nodes'] << ipaddress
        when /^supermarket-server\S+:/
          ipaddress = line.match(/^\s+ipaddress: (\S+)$/)[1]
          node.run_state['delivery']['stage']['data']['cluster_details']['supermarket_server']['url'] = ipaddress
        else
          if line =~ /^Chef Server URL.*$/
            ipaddress = URI(line.match(/^Chef Server URL:\s+(\S+)$/)[1]).host
            node.run_state['delivery']['stage']['data']['cluster_details']['chef_server']['url'] = ipaddress
          end
        end
        previous_line = line
      end
      ## Note: There is a temporal issue here where a new artifact could be promoted
      ## between provsioning and this call.
      latest_delivery_version = get_delivery_versions.first
      node.run_state['delivery']['stage']['data']['cluster_details']['delivery']['version'] = latest_delivery_version
    end
  end
end

delivery_stage_db
