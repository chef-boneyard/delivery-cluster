

directory "#{node['delivery']['workspace']['repo']}/environments"

template "#{node['delivery']['workspace']['repo']}/environments/aws.json" do
  source 'aws.json.erb'
  variables(
    :key_name => "builder_key"
  )
end

directory "#{node['delivery']['workspace']['cache']}/.aws"

template "#{node['delivery']['workspace']['cache']}/.aws/config" do
  source 'aws-config.erb'
  variables(
    :aws_access_key_id => "FROM_ENCRYPTED_DATA_BAG",
    :aws_secret_access_key => "FROM_ENCRYPTED_DATA_BAG",
    :region => "FROM_ENCRYPTED_DATA_BAG"
  )
end

execute "chef exec bundle install" do
  cwd "#{node['delivery']['workspace']['repo']}"
  action :run
end

execute "chef exec bundle exec berks vendor cookbooks" do
  cwd "#{node['delivery']['workspace']['repo']}"
  action :run
end

execute "chef exec bundle exec chef-client -z -o delivery-cluster::setup -E aws" do
  cwd "#{node['delivery']['workspace']['repo']}"
  environment (
    {
      'CHEF_ENV' => 'aws', 
      'AWS_CONFIG_FILE' => "#{node['delivery']['workspace']['cache']}/.aws/config"
    }
  )
  action :run
end