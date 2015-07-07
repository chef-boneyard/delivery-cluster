if defined?(ChefSpec)
  def converge_machine(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:machine, :converge, resource_name)
  end

  def download_machine_file(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:machine_file, :download, resource_name)
  end

  def run_machine_execute(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:machine_execute, :run, resource_name)
  end
end
