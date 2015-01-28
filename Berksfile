source 'https://supermarket.chef.io'

metadata

# TODO: Just use resources from chef-server-ingredients
cookbook 'chef-server-12',
  git: 'git@github.com:opscode-cookbooks/chef-server-12.git'

# TODO: get these cookbook changes merged to master
delivery_ref  = '_reviews/master/afiune/delivery_cluster_aws/latest'
delivery_repo = "ssh://#{ENV['USER']}@Chef@172.31.6.130:8989/Chef/Chef_Delivery/delivery"

cookbook 'delivery_builder',
  git: delivery_repo,
  rel: 'cookbooks/delivery_builder',
  branch: delivery_ref

cookbook 'delivery-server',
  git: delivery_repo,
  rel: 'cookbooks/delivery-server',
  branch: delivery_ref
