include_attribute 'delivery-matrix'

default['delivery-matrix']['acceptance']['matrix'] = [
  "clean_aws",
  "upgrade_aws",
  "clean_aws_dr",
  "upgrade_to_dr_aws"
]
