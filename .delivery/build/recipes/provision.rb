delivery_secrets = get_project_secrets
environment      = node['delivery']['change']['stage']
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

template File.join(path, "environments/#{environment}.json") do
  source 'environment.json.erb'
  variables(
    :delivery_license => "#{cache}/delivery.license",
    :environment => environment
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

execute "restore nodes and clients from outside workspace" do
  cwd path
  command <<-EOF
    mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/clients clients
    mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/nodes nodes
    mv /var/opt/delivery/workspace/delivery-cluster-aws-cache/delivery-cluster-data-* .chef/.
  EOF
  only_if do ::File.exists?('var/opt/delivery/workspace/delivery-cluster-aws-cache/nodes') end
end

# Destroy the old Delivery Cluster
execute "chef exec bundle exec chef-client -z -o delivery-cluster::destroy_all -E #{environment}" do
  cwd path
  environment ({
    'AWS_CONFIG_FILE' => "#{cache}/.aws/config"
  })
end

# Create a new Delivery Cluster
execute "chef exec bundle exec chef-client -z -o delivery-cluster::setup -E #{environment}" do
  cwd path
  environment ({
    'AWS_CONFIG_FILE' => "#{cache}/.aws/config"
  })
end

execute "copy the nodes and clients dir outside of workspace" do
  command <<-EOF
    cp -r clients nodes .chef/delivery-cluster-data-* /var/opt/delivery/workspace/delivery-cluster-aws-cache/
  EOF
  cwd path
end
