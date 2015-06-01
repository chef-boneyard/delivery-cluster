

# create environments directory
directory "#{node['chef-provisioning-node']['home']}/delivery-cluster/environments" do
  owner node['chef-provisioning-node']['user']
  group node['chef-provisioning-node']['user']
  mode '0755'
  recursive true
  action :create
end