require 'chef/provisioning/aws_driver'
with_driver 'aws'

with_machine_options(
  bootstrap_options: {
    instance_type: node['delivery-cluster']['aws']['flavor'],
    key_name: node['delivery-cluster']['aws']['key_name'],
    security_group_ids: node['delivery-cluster']['aws']['security_group_ids']
  },
  ssh_username: node['delivery-cluster']['aws']['ssh_username'],
  image_id:     node['delivery-cluster']['aws']['image_id']
)

add_machine_options bootstrap_options: { subnet_id: node['delivery-cluster']['aws']['subnet_id'] } if node['delivery-cluster']['aws']['subnet_id']
add_machine_options use_private_ip_for_ssh: node['delivery-cluster']['aws']['use_private_ip_for_ssh'] if node['delivery-cluster']['aws']['use_private_ip_for_ssh']
