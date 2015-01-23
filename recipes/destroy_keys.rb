
# Cleaning Keys
# => Builder Keys
execute "Deleting Builder Keys" do
  command "rm -rf #{tmp_infra_dir}/builder_key #{tmp_infra_dir}/builder_key.pub"
  action :run
end

# => Encrypted Secret Key
execute "Deleting Encrypted Secret Key" do
  command "rm -rf #{tmp_infra_dir}/encrypted_data_bag_secret"
  action :run
end

# => Org & Delivery User Keys
execute "Deleting Validator & Delivery User Keys" do
  command "rm -rf #{tmp_infra_dir}/validator.pem #{tmp_infra_dir}/delivery.pem"
  action :run
end

# => Enterprise Creds
execute "Deleting Validator & Delivery User Keys" do
  command "rm -rf #{tmp_infra_dir}/#{node['delivery-cluster']['delivery']['enterprise']}.creds"
  action :run
end
