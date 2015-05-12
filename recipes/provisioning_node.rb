# configure provision node

case node['platform_family']
when 'debian'
  include_recipe 'apt'
end

%w(build-essential git).each do |ir|
  include_recipe ir
end

chef_dk 'my_chef_dk' do
    version 'latest'
    global_shell_init true
    action :install
end

chef_gem 'knife-push'

# clone delivery-cluster cookbook to provisiong node
git "/home/vagrant/delivery-cluster" do
  repository "https://github.com/opscode-cookbooks/delivery-cluster.git"
  revision 'master'
  user 'vagrant'
  group 'vagrant'
  action :sync
end

# create environments directory
directory '/home/vagrant/delivery-cluster/environments' do
  owner 'vagrant'
  group 'vagrant'
  mode '0755'
  recursive true
  action :create
end

# install delivery-cli
case node['platform_family']
when 'debian'
  execute 'installing-delivery-cli' do
    command <<-EOF
      curl https://packagecloud.io/install/repositories/chef/current/script.deb | sudo bash
      sudo apt-get install delivery-cli
    EOF
    not_if('which delivery')
  end
when 'rhel'
  execute 'installing-delivery-cli' do
    command <<-EOF
      curl -o delivery-cli.rpm https://s3.amazonaws.com/delivery-packages/cli/delivery-cli-20150408004719-1.x86_64.rpm
      sudo yum install delivery-cli.rpm -y
    EOF
    not_if('which delivery')
  end
end

# setup ssh keys
directory '/home/vagrant/.ssh' do
  action :create
  owner 'vagrant'
  group 'vagrant'
  mode '0700'
end

cookbook_file '/home/vagrant/.ssh/insecure_private_key' do
  action :create
  owner 'vagrant'
  group 'vagrant'
  mode '0600'
  source 'insecure_private_key'
end

cookbook_file '/home/vagrant/.ssh/authorized_keys' do
  action :create
  owner 'vagrant'
  group 'vagrant'
  mode '0600'
  source 'insecure_public_key'
end