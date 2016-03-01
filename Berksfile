source 'https://supermarket.chef.io'

metadata

cookbook 'chef-server-12',
  path: 'vendor/chef-server-12'

cookbook 'hostsfile'

# Point to this repo until we can get this merged
# PR: https://github.com/hw-cookbooks/runit/pull/164
cookbook 'runit',
  git: 'https://github.com/afiune/runit.git',
  branch: 'afiune/make-it-work-in-oel'

cookbook 'chef-ingredient',
  git: 'https://github.com/chef-cookbooks/chef-ingredient.git'

cookbook 'chef-splunk',
  git: 'https://github.com/chef-cookbooks/chef-splunk.git'

cookbook 'delivery_build',
  git: 'https://github.com/chef-cookbooks/delivery_build.git'

cookbook 'delivery-base',
  git: 'https://github.com/chef-cookbooks/delivery-base.git'
