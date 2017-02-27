#
# Cookbook Name:: delivery-cluster
# Recipe:: setup_splunk
#
# Author:: Salim Afiune (<afiune@chef.io>)
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

include_recipe 'delivery-cluster::_settings'

# Provisioning Splunk Server
#
# TODO: This should be moved out but for now run:
# => # bundle exec chef-client -z -o delivery-cluster::setup_splunk -E test

directory "#{current_dir}/data_bags/vault" do
  recursive true
end

# Generating Splunk Certificate
execute 'Generating Splunk Key' do
  command "ssh-keygen -t rsa -N '' -b 2048 -f #{cluster_data_dir}/splunk.key"
  creates "#{cluster_data_dir}/splunk.key"
end

execute 'Generating Splunk CSR' do
  command <<-EOF
    openssl req -new -key #{cluster_data_dir}/splunk.key \
      -out #{cluster_data_dir}/splunk.csr \
      -subj "/C=US/ST=Washington/L=SplunkServer/O=Chef/OU=Chef Software/CN=self-signed.example.com"
  EOF
  creates "#{cluster_data_dir}/splunk.csr"
end

execute 'Generating Splunk Self-Signed Certificate' do
  command <<-EOF
    openssl x509 -req -days 365 -in #{cluster_data_dir}/splunk.csr \
      -signkey #{cluster_data_dir}/splunk.key \
      -out #{cluster_data_dir}/splunk.crt
  EOF
  creates "#{cluster_data_dir}/splunk.crt"
end

file "#{current_dir}/data_bags/vault/splunk_delivered.json" do
  content <<-EOF
    {
      "id": "splunk_delivered",
      "auth": "#{node['delivery-cluster']['splunk']['username']}:#{node['delivery-cluster']['splunk']['password']}"
    }
    EOF
end

file "#{current_dir}/data_bags/vault/splunk_certificates.json" do
  content lazy {
    JSON.generate(
      'id' => 'splunk_certificates',
      'data' => {
        'self-signed.example.com.crt' => File.read("#{cluster_data_dir}/splunk.crt"),
        'self-signed.example.com.key' => File.read("#{cluster_data_dir}/splunk.key"),
      }
    )
  }
end

# Here we go again. We need to provision the splunk server first and have
# it on the chef-server so when we greate the chef-vault it can be added
# as a trusted host. Thats why we first provision/bootstrap the instance.
machine splunk_server_hostname do
  chef_server lazy { chef_server_config }
  provisioning.specific_machine_options('splunk').each do |option|
    add_machine_options option
  end
  files lazy {
    {
      "/etc/chef/trusted_certs/#{chef_server_fqdn}.crt" => "#{Chef::Config[:trusted_certs_dir]}/#{chef_server_fqdn}.crt",
    }
  }
  action :converge
end

# ChefVault for Splunk Admin User Authentication
execute 'Creating ChefVault [splunk_delivered]' do
  cwd current_dir
  command <<-EOF
    knife vault create vault splunk_delivered \
      --json #{current_dir}/data_bags/vault/splunk_delivered.json \
      --search 'name:splunk-server*' --admins 'delivery' \
      --mode client
  EOF
  not_if 'knife data bag show vault splunk_delivered'
  action :run
end

# ChefVault for Splunk Web UI SSL
execute 'Creating ChefVault [splunk_certificates]' do
  cwd current_dir
  command <<-EOF
    knife vault create vault splunk_certificates \
      --json #{current_dir}/data_bags/vault/splunk_certificates.json \
      --search 'name:splunk-server*' --admins 'delivery' \
      --mode client
  EOF
  not_if 'knife data bag show vault splunk_certificates'
  action :run
end

upload_cookbook('chef-splunk')

chef_environment 'delivered' do
  chef_server lazy { chef_server_config }
end

# Installing splunk
machine splunk_server_hostname do
  chef_server lazy { chef_server_config }
  provisioning.specific_machine_options('splunk').each do |option|
    add_machine_options option
  end
  chef_environment 'delivered'
  common_cluster_recipes.each { |r| recipe r }
  recipe 'chef-splunk::server'
  attributes lazy {
    {
      'splunk' => {
        'accept_license' => true,
      },
    }
  }
  converge true
  action :converge
end

# Activate Splunk
activate_splunk

# Only available version
splunk_pkg  = 'analytics-splunk-app-1.0.0'
pkg_url     = 'https://github.com/chef/analytics-splunk-app/archive/v1.0.0.tar.gz'

# Download Analytics Splunk App
remote_file "#{cluster_data_dir}/#{splunk_pkg}.tar.gz" do
  source pkg_url
end

# Uploading Analytics Splunk App to Splunk Server
machine_file "/opt/splunk/etc/apps/#{splunk_pkg}.tar.gz" do
  chef_server lazy { chef_server_config }
  machine splunk_server_hostname
  local_path "#{cluster_data_dir}/#{splunk_pkg}.tar.gz"
  action :upload
end

machine_execute 'Unpackage Analytics Splunk App' do
  chef_server lazy { chef_server_config }
  machine splunk_server_hostname
  command <<-EOF
    sh -c "
      if [ ! -d /opt/splunk/etc/apps/#{splunk_pkg} ]
      then
        cd /opt/splunk/etc/apps
        tar -xvf #{splunk_pkg}.tar.gz
        chown -R splunk:splunk #{splunk_pkg}
        service splunk restart
      fi
    "
  EOF
end
