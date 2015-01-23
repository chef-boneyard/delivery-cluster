#
# General AWS Attributes
#
# In addition to this set of attributes you MUST have a ~/.aws/config file like this:
# => $ vi ~/.aws/config
# => [default]
# => region = us-east-1
# => aws_access_key_id = YOUR_ACCESS_KEY_ID
# => aws_secret_access_key = YOUR_SECRET_KEY 
default['aws']['key_name']            = 'afiune'
default['aws']['ssh_username']        = 'ubuntu' # CentOS 'root'
default['aws']['security_group_ids']  = 'sg-4bf8322f' 
default['aws']['image_id']            = 'ami-9eaa1cf6' # CentOS 'ami-3ce05354'
default['aws']['flavor']              = 't2.micro'

# => The Cluste Name which will be use to define all the server names 
cluster_id = 'test'

# Specific attributes
# => Delivery Server
default['delivery_cluster']['delivery']['hostname']    = "delivery-server-#{cluster_id}"
default['delivery_cluster']['delivery']['flavor']      = 't2.medium'
default['delivery_cluster']['delivery']['enterprise']  = 'my_enterprise'

# Delivery Artifacts
#
# There are three ways you can specify the Delivery Artifact
# 1) If you want to deploy the latest Delivery Build set the version to 'latest'
#    remember that this depend on Chef VPN Access
# => default['delivery_cluster']['delivery']['version'] = 'latest'
#
# 2) If you want to deploy a specific version you can also specify it
#    and it will pull it down from artifactory. VPN Access Needed!
#    To see the available versions go to:
#      * http://artifactory.chef.co/webapp/browserepo.html?4&pathId=omnibus-current-local:com/getchef/delivery
# => default['delivery_cluster']['delivery']['version']             = '0.2.21'
#
# 3) If you have the artifact URI you can specify it also and
#    this way you don't depend on VPN Access
# => default['delivery_cluster']['delivery']['version']             = '0.1.0_alpha.132'
# => default['delivery_cluster']['delivery']['debian']['artifact']  = 'https://s3.amazonaws.com/chef-delivery/dev/delivery-0.1.0_alpha.132%2B20141126080809-1.x86_64.rpm'
# => default['delivery_cluster']['delivery']['debian']['checksum']  = 'b279a4c7c0d277b9ec3f939c92a50970154eb7e56ddade4c2d701036aa27ee71'
#
default['delivery_cluster']['delivery']['version'] = 'latest'

# => Chef Server
default['delivery_cluster']['chef_server']['hostname']     = "chef-server-#{cluster_id}"
default['delivery_cluster']['chef_server']['organization'] = 'my_enterprise'
default['delivery_cluster']['chef_server']['flavor']       = 't2.small' 

# => Build Nodes
default['delivery_cluster']['build_nodes']['hostname'] = "build-node-#{cluster_id}"
default['delivery_cluster']['build_nodes']['role']     = 'delivery_builders'
default['delivery_cluster']['build_nodes']['N']        = 3
# default['delivery_cluster']['build_nodes']['flavor']   = 't2.small' 

