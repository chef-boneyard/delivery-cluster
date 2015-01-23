require 'chef/provisioning/aws_driver'

with_driver 'aws'

# Setting the chef-zero process
with_chef_server Chef::Config.chef_server_url

# Destroy Chef Server
machine node['delivery_cluster']['chef_server']['hostname'] do
  action :destroy
end
