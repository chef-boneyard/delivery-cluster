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

  def install_chef_ingredient(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:chef_ingredient, :install, resource_name)
  end

  def reconfigure_chef_ingredient(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:chef_ingredient, :reconfigure, resource_name)
  end

  def add_ingredient_config(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:ingredient_config, :add, resource_name)
  end
end
