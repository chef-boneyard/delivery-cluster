# This is the minimum config that is needed to let
# the provisioning cookbook `delivery-cluster` to work
current_dir       = File.dirname(__FILE__)
chef_repo_path    "#{current_dir}/.."
node_name         'delivery'
file_cache_path   File.join(current_dir, 'local-mode-cache', 'cache')
# Berkshelf no longer depedends on Chef so we avoid using the
# delivery_knife when running under a `berks` command.
if defined? ::Chef::Config
  delivery_knife    = File.join(current_dir, 'delivery-cluster-data', 'knife.rb')
  Chef::Config.from_file(delivery_knife) if File.exist?(delivery_knife)
end
cookbook_path "#{current_dir}/../cookbooks"
