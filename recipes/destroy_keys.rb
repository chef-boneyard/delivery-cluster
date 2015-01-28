#
# Cookbook Name:: delivery-cluster
# Recipe:: destroy_keys
#
# Copyright 2015, Chef Software, Inc.
#
# All rights reserved - Do Not Redistribute
#

%W(
   builder_key
   builder_key.pub
   encrypted_data_bag_secret
   validator.pem
   delivery.pem
   #{node['delivery-cluster']['delivery']['enterprise']}.creds
).each do |file|
  file File.join(tmp_infra_dir, file) do
    action :delete
  end
end
