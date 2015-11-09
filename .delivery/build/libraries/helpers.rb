#
# Cookbook Name:: build
# Library:: helpers
#
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
    src = ::Dir.glob(::File.join(path, dir))
    dst = ::File.dirname(::File.join(backup_dir, dir))
    unless src.empty?
      FileUtils.mkdir_p(dst)
      FileUtils.cp_r(src, dst)
    end
  end
end

# Restore Cluster Data
#
# Method that will move the Cluster Data from the Brackup Directory to
# the `running phase path`
def restore_cluster_data(path)
  critical_cluster_dirs.each do |dir|
    src = ::Dir.glob(::File.join(backup_dir, dir))
    dst = ::File.dirname(::File.join(path, dir))
    unless src.empty?
      FileUtils.mkdir_p(dst)
      FileUtils.mv(src, dst)
    end
  end
end

# List of Critical Cluster Directories
#
# These are the critical directories that we need to backu and restore
# to be able to manipulate old Delivery Clusters
def critical_cluster_dirs
  [
    'repo/clients',
    'repo/nodes',
    'repo/.chef/delivery-cluster-data-*',
    'cache/.chef/trusted_certs/*'
  ]
end

# Timeout for Delivery Cluster commands
#
# Some of the Delivery Cluster commands take more than an hour to run
# We are setting the cluster timeout to 2 hours
def cluster_timeout
  7200
end

Chef::Recipe.send(:include, Chef::Mixin::ShellOut)
Chef::Resource.send(:include, Chef::Mixin::ShellOut)
