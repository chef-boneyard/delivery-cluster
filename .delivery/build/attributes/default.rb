include_attribute 'delivery-matrix'

# Turning these off for now becuase of some build failures related to
# the artifactory switchover. Will likely need a fix to delivery-sugar-extras to fix

default['delivery-matrix']['acceptance']['matrix'] = []

#default['delivery-matrix']['acceptance']['matrix'] = [
#  "clean_aws",
#  "upgrade_aws",
#  "clean_aws_dr",
#  "upgrade_to_dr_aws"
#]
