#
# Cookbook Name:: build
# Recipe:: provision
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

if node['delivery']['change']['pipeline'] == 'master' &&
   node['delivery']['change']['stage'] == 'union'
  # This was lifted from delivery-truck publish
  secrets = get_project_secrets
  github_repo = node['delivery']['config']['delivery-truck']['publish']['github']

  delivery_github github_repo do
    deploy_key secrets['github']
    branch node['delivery']['change']['pipeline']
    remote_url "git@github.com:#{github_repo}.git"
    repo_path node['delivery']['workspace']['repo']
    cache_path node['delivery']['workspace']['cache']
    action :push
  end
end

# By including this recipe we trigger a matrix of acceptance envs specified
# in the node attribute node['delivery-red-pill']['acceptance']['matrix']
include_recipe "delivery-red-pill::provision"
