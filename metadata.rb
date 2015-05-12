name             'delivery-cluster'
maintainer       'Chef Delivery Team'
maintainer_email 'delivery-team@chef.io'
license          'Apache 2.0'
description      'Deployment cookbook for standing up Delivery Clusters'
long_description 'Installs Chef Delivery, a solution for continuously ' \
                 'delivering applications and infrastructure safely at speed'
version          '0.2.16'

depends 'chef-server-12'
depends 'chef-server-ingredient'
depends 'git'
depends 'push-jobs'
depends 'chef-splunk'
depends 'packagecloud'
depends 'supermarket-omnibus-cookbook'

# provisioning-node
%w(apt build-essential git chef-dk).each do |cb|
  depends cb
end
