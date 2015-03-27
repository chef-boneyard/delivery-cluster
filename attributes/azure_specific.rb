# General Azure Attributes
#
# In addition to this set of attributes you MUST have a ~/.azure/config file like this:
# => $ vi ~/.azure/config
# [default]
# management_certificate = "/Users/alexvinyar/Documents/Projects/Azure/managementCertificate.pem"
# subscription_id = "43e53945-f02b-4269-8854-ad7dd14ac6f2" # this will be same for everyone, at least for the time being.
# for directions on how to generate a pem, please refer to knife azure plugin documentation
# here: https://github.com/chef/knife-azure

# A lot of this will need to be refactored
default['delivery-cluster']['cloud']     = 'azure' # set to 'azure' or 'aws' # default should be aws
# in environment file
# default['delivery-cluster']['id'] = 'alexv' # this needs to be in the environment.

# General settings
default['delivery-cluster']['azure']['flavor'] = 'Medium'
default['delivery-cluster']['azure']['location'] = 'West US'
# aws ami for reference ubuntu-trusty-14.04-amd64-server-20140927 (ami-3d50120d)
default['delivery-cluster']['azure']['image_id'] = 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_1-LTS-amd64-server-20140927-en-us-30GB' # defined in Environment
default['delivery-cluster']['azure']['id'] = 'alexv' # defined in Environment
default['delivery-cluster']['azure']['storage_account_name'] = 'alexvstorageacct03'


# default['delivery-cluster']['chef-server']['azureflavor'] = 'Medium'
default['delivery-cluster']['chef-server']['cloud_service_name'] = 'alexvchefserver01'


# default['delivery-cluster']['delivery-server']['azureflavor'] = 'Medium'
default['delivery-cluster']['delivery-server']['cloud_service_name'] = 'alexvdeliveryserver01'


## Right now all attributes below this line have no meaning.
default['delivery-cluster']['azure']['key_name']                = ENV['USER']
default['delivery-cluster']['azure']['ssh_username']            = nil
default['delivery-cluster']['azure']['security_group_ids']      = nil
default['delivery_cluster']['azure']['subnet_id']               = nil
default['delivery-cluster']['azure']['use_private_ip_for_ssh']  = false

