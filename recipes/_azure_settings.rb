require 'chef/provisioning/aws_driver'
with_driver 'azure'
# require 'pry'; binding.pry
with_machine_options(
  bootstrap_options: {
    # vm_size: node['delivery-cluster']['azure']['flavor'],
    # #required
    # location: node['delivery-cluster']['azure']['location'],
    # # cloud_service_name: nil, # has to be unique per box
    # #required # can be shared across boxes per Gitter
    # storage_account_name: node['delivery-cluster']['azure']['storage_account_name']
  },
  image_id: node['delivery-cluster']['azure']['image_id'],
  password: "chefm3t4lB/la\\" #required  
)

# add_machine_options bootstrap_options: { subnet_id: node['delivery-cluster']['aws']['subnet_id'] } if node['delivery-cluster']['aws']['subnet_id']
# add_machine_options use_private_ip_for_ssh: node['delivery-cluster']['aws']['use_private_ip_for_ssh'] if node['delivery-cluster']['aws']['use_private_ip_for_ssh']



# machine_options = {
#     :bootstrap_options => {
#       # :cloud_service_name => 'chefprovisioning', #required - old
#       :cloud_service_name => 'alexvcloudservice02', #required
#       # :storage_account_name => 'chefprovisioning', #required
#       :storage_account_name => 'alexvstorageacct02', #required
#       :vm_size => "Small", #required
#       :location => 'West US'#, #required
#       # :tcp_endpoints => '80:80' #optional
#     },
#     :image_id => 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_1-LTS-amd64-server-20140927-en-us-30GB', #required
#     # Until SSH keys are supported (soon)
#     :password => "chefm3t4lB/la\\" #required
# }
