source 'https://supermarket.chef.io'

metadata

# TODO: Just use resources from chef-server-ingredients
cookbook 'chef-server-12',
  git: 'git@github.com:opscode-cookbooks/chef-server-12.git'

delivery_ref  = 'master'
delivery_repo = "git@github.com:chef/delivery.git"

cookbook 'delivery_builder',
  git: delivery_repo,
  rel: 'cookbooks/delivery_builder',
  branch: delivery_ref

cookbook 'delivery-server',
  git: delivery_repo,
  rel: 'cookbooks/delivery-server',
  branch: delivery_ref
