require 'chef/provisioning/aws_driver'

with_driver 'aws'

# Only if we have the credentials to destroy it
if File.exist?("#{tmp_infra_dir}/delivery.pem")
  begin
    # Only if there is an active chef server
    chef_node = Chef::Node.load(node['delivery-cluster']['chef-server']['hostname'] )
    chef_server_ip = chef_node['ec2']['public_ipv4']

    # Setting the new Chef Server we just created
    with_chef_server "https://#{chef_server_ip}/organizations/#{node['delivery-cluster']['chef-server']['organization']}",
      :client_name => "delivery",
      :signing_key_filename => "#{tmp_infra_dir}/delivery.pem"

    # Destroy Delivery Server
    machine node['delivery-cluster']['delivery']['hostname']  do
      action :destroy
    end

    # Delivery is gone. Why do we need the keys?
    # => Org & Delivery User Keys
    execute "Deleting Delivery User Keys" do
      command "rm -rf #{tmp_infra_dir}/delivery.pem"
      action :run
    end

    # => Enterprise Creds
    execute "Deleting Validator & Delivery User Keys" do
      command "rm -rf #{tmp_infra_dir}/#{node['delivery-cluster']['delivery']['enterprise']}.creds"
      action :run
    end
  rescue Exception => e
    Chef::Log.warn("We can't proceed to destroy the Delivery Server.")
    Chef::Log.warn("We couldn't get the chef-server Public IP: #{e.message}")
  end
else
  log "Skipping Delivery Server deletion because missing delivery.pem key"
end
