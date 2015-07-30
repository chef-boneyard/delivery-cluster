#
# Cookbook Name:: build
# Library:: helpers
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# Backup directory
#
# This directory must be outside the project path so it is persistent
# across changes. Here we will store the critical cluster data for aws
def backup_dir
  '/var/opt/delivery/workspace/delivery-cluster-aws-cache'
end

# Backup Cluster Data
#
# Method that will copy the Cluster Data from the `running phase path` to
# the Brackup Directory
def backup_cluster_data(path)
  critical_cluster_dirs.each do |dir|
    src = ::File.join(path, dir)
    dst = ::File.join(backup_dir, dir)
    FileUtils.cp_r src, dst
  end
end

# Restore Cluster Data
#
# Method that will move the Cluster Data from the Brackup Directory to
# the `running phase path`
def restore_cluster_data(path)
  critical_cluster_dirs.each do |dir|
    src = ::File.join(backup_dir, dir)
    dst = ::File.join(path, dir)
    FileUtils.mv src, dst if ::File.exists?(src)
  end
end

# List of Critical Cluster Directories
#
# These are the critical directories that we need to backu and restore
# to be able to manipulate old Delivery Clusters
def critical_cluster_dirs
  [
    'clients',
    'nodes',
    '.chef/trusted_certs',
    '.chef/delivery-cluster-data-*'
  ]
end

Chef::Recipe.send(:include, Chef::Mixin::ShellOut)
Chef::Resource.send(:include, Chef::Mixin::ShellOut)
