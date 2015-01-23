
def current_dir
  @current_dir ||= Chef::Config.chef_repo_path
end

def tmp_infra_dir
  @tmp_infra_dir ||= File.join(current_dir, "infra/tmp")
end

def dot_chef_dir
  @dot_chef_dir ||= File.join(current_dir, '.chef')
end
