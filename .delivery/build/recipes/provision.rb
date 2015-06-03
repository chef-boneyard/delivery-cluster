

delivery_secrets = get_project_secrets

directory File.join(node['delivery']['workspace']['cache'], '.ssh')

ssh_private_key_path =  File.join(node['delivery']['workspace']['cache'], '.ssh', "chef-delivery-cluster")
ssh_public_key_path =  File.join(node['delivery']['workspace']['cache'], '.ssh', "chef-delivery-cluster.pub")

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

directory "#{node['delivery']['workspace']['repo']}/environments"

template "#{node['delivery']['workspace']['repo']}/environments/aws.json" do
  source 'aws.json.erb'
  variables(
    :delivery_license => "#{node['delivery']['workspace']['cache']}/delivery.license"
  )
end

directory "#{node['delivery']['workspace']['cache']}/.aws"

template "#{node['delivery']['workspace']['cache']}/.aws/config" do
  source 'aws-config.erb'
  variables(
    :aws_access_key_id => delivery_secrets['access_key_id'],
    :aws_secret_access_key => delivery_secrets['secret_access_key'],
    :region => delivery_secrets['region']
  )
end

s3_file "#{node['delivery']['workspace']['cache']}/delivery.license" do
  remote_path "licenses/delivery-internal.license"
  bucket "delivery-packages"
  aws_access_key_id delivery_secrets['access_key_id']
  aws_secret_access_key delivery_secrets['secret_access_key']
  action :create
end

execute "chef exec bundle install" do
  cwd node['delivery']['workspace']['repo']
  action :run
end

execute "chef exec bundle exec berks vendor cookbooks" do
  cwd node['delivery']['workspace']['repo']
  action :run
end

execute "restore nodes and clients from outside workspace" do
  command <<-EOF
    mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/clients clients
    mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/nodes nodes
    mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/delivery-cluster-data-aws .chef/delivery-cluster-data-aws
    rm -rf /var/opt/delivery/workspace/delivery-cluster-aws-cache
  EOF
  cwd node['delivery']['workspace']['repo']
  action :run
  only_if do ::File.exists?('var/opt/delivery/workspace/delivery-cluster-aws-cache/nodes') end
end

# destroy everything
execute "chef exec bundle exec chef-client -z -o delivery-cluster::destroy_all -E aws" do
  cwd node['delivery']['workspace']['repo']
  environment (
    {
      'CHEF_ENV' => 'aws', 
      'AWS_CONFIG_FILE' => "#{node['delivery']['workspace']['cache']}/.aws/config"
    }
  )
  action :run
end

execute "chef exec bundle exec chef-client -z -o delivery-cluster::setup -E aws" do
  cwd node['delivery']['workspace']['repo']
  environment (
    {
      'CHEF_ENV' => 'aws', 
      'AWS_CONFIG_FILE' => "#{node['delivery']['workspace']['cache']}/.aws/config"
    }
  )
  action :run
end

execute "copy the nodes and clients dir outside of workspace" do
  command <<-EOF
    cp -r clients nodes .chef/delivery-cluster-data-aws /var/opt/delivery/workspace/delivery-cluster-aws-cache/
  EOF
  cwd node['delivery']['workspace']['repo']
  action :run
end

