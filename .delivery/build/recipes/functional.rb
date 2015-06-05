#
# Cookbook Name:: build
# Recipe:: functional
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# ## By including this recipe we trigger a matrix of acceptance envs specified
# ## in the node attribute node['delivery-red-pill']['acceptance']['matrix']
include_recipe "delivery-red-pill::functional"
