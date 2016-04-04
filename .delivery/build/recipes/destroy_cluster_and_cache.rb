
delivery_secrets = get_project_secrets
cluster_name     = "#{node['delivery']['change']['stage']}_#{node['delivery']['change']['pipeline']}"
root             = node['delivery']['workspace']['root']
path             = node['delivery']['workspace']['repo']
cache            = node['delivery']['workspace']['cache']

ruby_block 'Destroy Delivery Cluster and Delete Cache in S3' do
  block do
    restore_cluster_data(root, node, delivery_secrets)

    shell_out(
      'rake destroy:all',
      :cwd => path,
      :timeout => cluster_timeout,
      :live_stream => STDOUT,
      :environment => {
        'CHEF_ENV' => cluster_name,
        'AWS_CONFIG_FILE' => "#{cache}/.aws/config"
      }
    )

    destroy_cluster_data(root, node, delivery_secrets)
  end
end

# Clean up cache directory and gzip cache file
file zip_file(node) do
  action :delete
end

directory backup_dir(node) do
  action :delete
  recursive true
end
