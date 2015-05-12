# configure provision node

case node['platform_family']
when 'debian'
  include_recipe 'apt'
end

%w(build-essential git).each do |ir|
  include_recipe ir
end

package 'chefdk' do
  action :upgrade
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

package 'delivery-cli' do
  action :upgrade
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