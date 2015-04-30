class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def pink
    colorize(35)
  end
end

ENV['CHEF_ENV'] ||= "test"
ENV['CHEF_ENV_FILE'] = "environments/#{ENV['CHEF_ENV']}.json"

def chef_zero(recipe)
  system "bundle exec chef-client -z -o delivery-cluster::#{recipe} -E #{ENV['CHEF_ENV']}"
end

def msg(string)
  puts "\n#{string}\n".yellow
end

Rake::TaskManager.record_task_metadata = true

namespace :setup do
  desc 'Install all the prerequisites on you system'
  task :prerequisites do
    msg "Install rubygem dependencies locally"
    system "bundle install"

    msg "Download and vendor the necessary cookbooks locally"
    system "bundle exec berks vendor cookbooks"

    msg "Current chef environment => #{ENV['CHEF_ENV_FILE']}"
    if File.exist?(ENV['CHEF_ENV_FILE'])
      puts "You need to configure an Environment under 'environments/'. Check the README.md".red
      puts "If you just have a different chef environment name run:"
      puts "  # export CHEF_ENV=#{"my_new_environment".yellow}"
    end
  end

  desc 'Setup the Chef Delivery Cluster that includes: [ Chef Server | Delivery Server | Build Nodes ]'
  task :cluster => [:prerequisites] do
    msg "Setup the Chef Delivery cluster"
    chef_zero 'setup'
  end

  desc 'Setup a Chef Server'
  task :chef_server do
    msg "Create a Chef Server"
    chef_zero 'setup_chef_server'
  end

  desc 'Create a Delivery Server & Build Nodes'
  task :delivery do
    msg "Create Delivery Server and Build Nodes"
    chef_zero 'setup_delivery'
  end

  desc 'Activate Analytics Server'
  task :analytics => [:chef_server] do
    msg "Setup Chef Analytics so we can see what is going on in our cluster"
    chef_zero 'setup_analytics'
  end

  desc 'Create a Splunk Server with Analytics Integration'
  task :splunk => [:analytics] do
    msg "Setup Splunk Server to show some Analytics Integrations"
    chef_zero 'setup_splunk'
  end

  desc 'Create a Supermarket Server'
  task :supermarket => [:chef_server] do
    msg "Setup Supermarket Server to resolve cookbook dependencies"
    chef_zero 'setup_supermarket'
  end
end

namespace :maintenance do
  desc 'Upgrade your infrastructure'
  task :upgrade => [:clean_cache, :update] do
    Rake::Task['setup:cluster'].invoke
  end

  task :update do
    msg "Updating cookbooks locally"
    system "bundle exec berks update"
  end

  desc 'Clean the cache'
  task :clean_cache do
    FileUtils.rm_rf(".chef/local-mode-cache")
    FileUtils.rm_rf("cookbooks/")
  end
end

namespace :destroy do
  desc 'Destroy Everything'
  task :all do
    chef_zero 'destroy_all'
  end

  desc 'Destroy Analytics Server'
  task :analytics do
    chef_zero 'destroy_analytics'
  end

  desc 'Destroy Splunk Server'
  task :splunk do
    chef_zero 'destroy_splunk'
  end

  desc 'Destroy Supermarket Server'
  task :supermarket do
    chef_zero 'destroy_supermarket'
  end

  desc 'Destroy Build Nodes'
  task :builders do
    chef_zero 'destroy_builders'
  end

  desc 'Destroy Delivery Server'
  task :delivery do
    chef_zero 'destroy_delivery'
  end

  desc 'Destroy Chef Server'
  task :chef_server do
    chef_zero 'destroy_chef_server'
  end
end

namespace :info do
  desc 'Show Delivery admin credentials'
  task :delivery_creds do
    # TODO - use Ruby to read these files so its cross-platform
    system "cat .chef/delivery-cluster-data/*.creds"
  end

  desc 'List all your core services'
  task :list_core_services do
    system "knife search node 'name:*server* OR name:build-node*' -a ipaddress"
    system "grep chef_server_url .chef/delivery-cluster-data/knife.rb"
  end
end


task :default => [:help]
task :help do
  puts "\nDelivery Cluster Helper".green
  puts "\nSetup Tasks".pink
  puts "The following tasks should be used to set up your cluster".yellow
  Rake::application.options.show_tasks = :tasks  # this solves sidewaysmilk problem
  Rake::application.options.show_task_pattern = /setup/
  Rake::application.display_tasks_and_comments
  puts "\nMaintenance Tasks".pink
  puts "The following tasks should be used to maintain your cluster".yellow
  Rake::application.options.show_task_pattern = /maintenance/
  Rake::application.display_tasks_and_comments
  puts "\nDestroy Tasks".pink
  puts "The following tasks should be used to destroy your cluster".yellow
  Rake::application.options.show_task_pattern = /destroy/
  Rake::application.display_tasks_and_comments
  puts "\nCluster Information".pink
  puts "The following tasks should be used to get information about your cluster".yellow
  Rake::application.options.show_task_pattern = /info/
  Rake::application.display_tasks_and_comments
  puts "\nTo switch your environment run:"
  puts "  # export CHEF_ENV=#{"my_new_environment".yellow}\n"
end
