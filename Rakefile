require 'fileutils'
require 'erb'
require 'json'

# String Colorization
class String
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

# Delivery Environment for ERB Rendering
class DeliveryEnvironment
  def initialize(name, options)
    options.each_pair do |key, value|
      instance_variable_set('@' + key.to_s, value)
    end
    @name = name
    @data = json
  end

  def self.template
    '<%= JSON.pretty_generate(@data) %>'
  end

  def json
    {
      'name' => @name,
      'description' => 'Delivery Cluster Environment',
      'json_class' => 'Chef::Environment',
      'chef_type' => 'environment',
      'override_attributes' => {
        'delivery-cluster' => {
          'id' => @cluster_id,
          'driver' => @driver_name,
          @driver_name => @driver,
          'chef-server' => @chef_server,
          'delivery' => @delivery,
          'analytics' => (@analytics if @analytics && ! @analytics.empty?),
          'supermarket' => (@supermarket if @supermarket && ! @supermarket.empty?),
          'builders' => @builders
        }.delete_if { |_k, v| v.nil? }
      }
    }
  end

  def do_binding
    binding
  end
end

ENV['CHEF_ENV'] ||= 'test'
ENV['CHEF_ENV_FILE'] = "environments/#{ENV['CHEF_ENV']}.json"

# Validate the environment file
#
# If the environment file does not exist or it has syntax errors fail fast
def validate_environment
  unless File.exist?(ENV['CHEF_ENV_FILE'])
    puts 'You need to configure an Environment under \'environments/\'. Check the README.md'.red
    puts 'You can use the \'generate_env\' task to auto-generate one:'
    puts '  # rake setup:generate_env'
    puts "\nOr if you just have a different chef environment name run:"
    puts "  # export CHEF_ENV=#{'my_new_environment'.yellow}"
    fail
  end

  begin
    JSON.parse(File.read(ENV['CHEF_ENV_FILE']))
  rescue JSON::ParserError
    puts "You have syntax errors on the environment file '#{ENV['CHEF_ENV_FILE']}'".red
    puts 'Please fix the problems and re run the task.'
    raise
  end
end

def chef_apply(recipe)
  succeed = system "chef exec chef-apply recipes/#{recipe}.rb"
  fail 'Failed executing ChefApply run' unless succeed
end

def chefdk_version
  @chef_dk_version ||= `chef -v`.split("\n").first.split.last
rescue
  puts 'ChefDk was not found'.red
  puts 'Please install it from: https://downloads.chef.io/chef-dk'.yellow
  raise
end

def chef_zero(recipe)
  validate_environment
  succeed = system "chef exec chef-client -z -o delivery-cluster::#{recipe} -E #{ENV['CHEF_ENV']}"
  fail 'Failed executing ChefZero run' unless succeed
end

def render_environment(environment, options)
  ::FileUtils.mkdir_p 'environments'

  env_file = File.open("environments/#{environment}.json", 'w+')
  env_file << ERB.new(DeliveryEnvironment.template)
    .result(DeliveryEnvironment.new(environment, options).do_binding)
  env_file.close

  puts File.read("environments/#{environment}.json")
end

def bool(string)
  case string
  when 'no'
    false
  when 'yes'
    true
  else
    string
  end
end

def ask_for(thing, default = nil)
  thing = "#{thing} [#{default.yellow}]: " if default
  stdin = nil
  loop do
    print thing
    stdin = STDIN.gets.strip
    case default
    when 'no', 'yes'
      break if stdin.empty? || stdin.eql?('no') || stdin.eql?('yes')
      print 'Answer (yes/no) '
    when nil
      break unless stdin.empty?
    else
      break
    end
  end
  bool(stdin.empty? ? default : stdin)
end

def msg(string)
  puts "\n#{string}\n".yellow
end

Rake::TaskManager.record_task_metadata = true

namespace :setup do
  desc 'Generate an Environment'
  task :generate_env do
    msg 'Gathering Cluster Information'
    puts 'Provide the following information to generate your environment.'

    options = {}
    puts "\nGlobal Attributes".pink
    # Environment Name
    environment = ask_for('Environment Name', 'test')

    if File.exist? "environments/#{environment}.json"
      puts "ERROR: Environment environments/#{environment}.json already exist".red
      exit 1
    end

    options['cluster_id'] = ask_for('Cluster ID', environment)
    puts "\nAvailable Drivers: [ aws | ssh | vagrant ]"
    options['driver_name'] = ask_for('Driver Name', 'vagrant')

    puts "\nDriver Information [#{options['driver_name']}]".pink
    options['driver'] = {}
    case options['driver_name']
    when 'ssh'
      options['driver']['ssh_username'] = ask_for('SSH Username', 'vagrant')
      # TODO: Ask for 'password' when we are ready to encrypt it
      loop do
        puts 'Key File Not Found'.red if options['driver']['key_file']
        options['driver']['key_file'] = ask_for('Key File',
                                                File.expand_path('~/.vagrant.d/insecure_private_key'))
        break if File.exist?(options['driver']['key_file'])
      end
    when 'aws'
      options['driver']['key_name']           = ask_for('Key Name: ')
      options['driver']['ssh_username']       = ask_for('SSH Username', 'ubuntu')
      options['driver']['image_id']           = ask_for('Image ID', 'ami-3d50120d')
      options['driver']['subnet_id']          = ask_for('Subnet ID', 'subnet-19ac017c')
      options['driver']['security_group_ids'] = ask_for('Security Group ID', 'sg-cbacf8ae')
      options['driver']['use_private_ip_for_ssh'] = ask_for('Use private ip for ssh?', 'yes')
    when 'vagrant'
      options['driver']['ssh_username']           = ask_for('SSH Username', 'vagrant')
      options['driver']['vm_box']                 = ask_for('Box Type: ', 'opscode-centos-6.6')
      options['driver']['image_url']              = ask_for('Box URL: ', 'https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.6_chef-provisionerless.box')
      options['driver']['use_private_ip_for_ssh'] = ask_for('Use private ip for ssh?', 'yes')
      loop do
        puts 'Key File Not Found'.red if options['driver']['key_file']
        options['driver']['key_file'] = ask_for('Key File',
                                                File.expand_path('~/.vagrant.d/insecure_private_key'))
        break if File.exist?(options['driver']['key_file'])
      end
    else
      puts 'ERROR: Unsupported Driver.'.red
      puts 'Available Drivers are [ vagrant | aws | ssh ]'.yellow
      exit 1
    end
    # Proxy Settings
    if ask_for('Would you like to configure Proxy Settings?', 'no')
      http_proxy  = ask_for('http_proxy: ')
      https_proxy = ask_for('https_proxy: ')
      no_proxy    = ask_for('no_proxy: ')
      options['driver']['bootstrap_proxy'] = https_proxy || http_proxy || nil
      options['driver']['chef_config']     = "http_proxy '#{http_proxy}'\n" \
                                             "https_proxy '#{https_proxy}'\n" \
                                             "no_proxy '#{no_proxy}'"
    end

    puts "\nChef Server".pink
    options['chef_server'] = {}
    options['chef_server']['organization'] = ask_for('Organization Name', environment)
    options['chef_server']['existing']     = ask_for('Use existing chef-server?', 'no')
    unless options['chef_server']['existing']
      case options['driver_name']
      when 'aws'
        options['chef_server']['flavor'] = ask_for('Flavor', 'c3.xlarge')
      when 'ssh'
        options['chef_server']['host'] = ask_for('Host', '33.33.33.10')
      when 'vagrant'
        options['chef_server']['vm_hostname'] = 'chef.example.com'
        options['chef_server']['network'] = ask_for('Network Config', ":private_network, {:ip => '33.33.33.10'}")
        options['chef_server']['vm_memory'] = ask_for('Memory allocation', '2048')
        options['chef_server']['vm_cpus'] = ask_for('Cpus allocation', '2')
      end
    end

    puts "\nDelivery Server".pink
    options['delivery'] = {}
    options['delivery']['version']      = ask_for('Package Version', 'latest')
    options['delivery']['enterprise']   = ask_for('Enterprise Name', environment)
    options['delivery']['license_file'] = ask_for('License File',
                                                  File.expand_path('~/delivery.license'))
    unless File.exist?(options['delivery']['license_file'])
      puts 'License File Not Found'.red
      puts 'Please confirm the location of the license file.'.yellow
      exit 1
    end

    case options['driver_name']
    when 'aws'
      options['delivery']['flavor'] = ask_for('Flavor', 'c3.xlarge')
    when 'ssh'
      options['delivery']['host'] = ask_for('Host', '33.33.33.11')
    when 'vagrant'
      options['delivery']['vm_hostname'] = 'delivery.example.com'
      options['delivery']['network'] = ask_for('Network Config', ":private_network, {:ip => '33.33.33.11'}")
      options['delivery']['vm_memory'] = ask_for('Memory allocation', '2048')
      options['delivery']['vm_cpus'] = ask_for('Cpus allocation', '2')
    end

    puts "\nAnalytics Server".pink
    if ask_for('Enable Analytics?', 'no')
      options['analytics'] = {}
      case options['driver_name']
      when 'aws'
        options['analytics']['flavor'] = ask_for('Flavor', 'c3.xlarge')
      when 'ssh'
        options['analytics']['host'] = ask_for('Host', '33.33.33.12')
      when 'vagrant'
        options['analytics']['vm_hostname'] = 'analytics.example.com'
        options['analytics']['network'] = ask_for('Network Config', ":private_network, {:ip => '33.33.33.12'}")
        options['analytics']['vm_memory'] = ask_for('Memory allocation', '2048')
        options['analytics']['vm_cpus'] = ask_for('Cpus allocation', '2')
      end
    end

    puts "\nSupermarket Server".pink
    if ask_for('Enable Supermarket?', 'no')
      options['supermarket'] = {}
      case options['driver_name']
      when 'aws'
        options['supermarket']['flavor'] = ask_for('Flavor', 'c3.xlarge')
      when 'ssh'
        options['supermarket']['host'] = ask_for('Host', '33.33.33.13')
      when 'vagrant'
        options['supermarket']['vm_hostname'] = 'supermarket.example.com'
        options['supermarket']['network'] = ask_for('Network Config', ":private_network, {:ip => '33.33.33.13'}")
        options['supermarket']['vm_memory'] = ask_for('Memory allocation', '2048')
        options['supermarket']['vm_cpus'] = ask_for('Cpus allocation', '2')
      end
    end

    puts "\nBuild Nodes".pink
    options['builders'] = {}
    options['builders']['count'] = ask_for('Number of Build Nodes', '1')
    case options['driver_name']
    when 'aws'
      options['builders']['flavor'] = ask_for('Flavor', 'c3.large')
    when 'ssh'
      1.upto(options['builders']['count'].to_i) do |i|
        h = ask_for("Host for Build Node #{i}", "33.33.33.1#{i + 3}")
        options['builders'][i] = { 'host' => h }
      end
    when 'vagrant'
      1.upto(options['builders']['count'].to_i) do |i|
        net = ask_for("Network for Build Node #{i}", ":private_network, {:ip => '33.33.33.1#{i + 3}'}")
        mem = ask_for("Memory allocation for Build Node #{i}", '2048')
        cpu = ask_for("Cpus allocation for Build Node #{i}", '2')
        options['builders'][i] = { 'network' => net, 'vm_memory' => mem, 'vm_cpus' => cpu }
      end
    end

    msg "Rendering Environment => environments/#{environment}.json"

    render_environment(environment, options)

    puts "\nExport your new environment by executing:".yellow
    puts "  # export CHEF_ENV=#{environment.green}\n"
  end

  desc 'Install all the prerequisites on you system'
  task :prerequisites do
    msg 'Verifying ChefDK version'
    if Gem::Version.new(chefdk_version) < Gem::Version.new('0.10.0')
      puts "Running ChefDK version #{chefdk_version}".red
      puts 'The required version is >= 0.10.0'.red
      fail
    else
      puts "Running ChefDK version #{chefdk_version}".green
    end

    msg 'Configuring the provisioner node'
    chef_apply 'provisioner'

    msg 'Download and vendor the necessary cookbooks locally'
    system 'chef exec berks vendor cookbooks'

    msg "Current chef environment => #{ENV['CHEF_ENV_FILE']}"
    validate_environment
  end

  desc 'Setup the Chef Delivery Cluster that includes: [ Chef Server | Delivery Server | Build Nodes ]'
  task cluster: [:prerequisites] do
    msg 'Setup the Chef Delivery cluster'
    chef_zero 'setup'
  end

  desc 'Setup a Chef Server'
  task :chef_server do
    msg 'Create a Chef Server'
    chef_zero 'setup_chef_server'
  end

  desc 'Create a Delivery Server & Build Nodes'
  task :delivery do
    msg 'Create Delivery Server and Build Nodes'
    chef_zero 'setup_delivery'
  end

  desc 'Create a Delivery Server only'
  task :delivery_server do
    msg 'Create Delivery Server'
    chef_zero 'setup_delivery_server'
  end

  desc 'Create Delivery Build Nodes'
  task :delivery_build_nodes do
    msg 'Create Delivery Build Nodes'
    chef_zero 'setup_delivery_builders'
  end

  desc 'Activate Analytics Server'
  task analytics: [:chef_server] do
    msg 'Setup Chef Analytics so we can see what is going on in our cluster'
    chef_zero 'setup_analytics'
  end

  desc 'Create a Splunk Server with Analytics Integration'
  task splunk: [:analytics] do
    msg 'Setup Splunk Server to show some Analytics Integrations'
    chef_zero 'setup_splunk'
  end

  desc 'Create a Supermarket Server'
  task supermarket: [:chef_server] do
    msg 'Setup Supermarket Server to resolve cookbook dependencies'
    chef_zero 'setup_supermarket'
  end
end

namespace :maintenance do
  desc 'Upgrade Delivery'
  task upgrade: [:clean_cache] do
    Rake::Task['setup:cluster'].invoke
  end

  desc 'Update cookbook dependencies'
  task :update do
    msg 'Updating cookbooks locally'
    system 'chef exec berks update'
  end

  desc 'Clean the cache'
  task :clean_cache do
    FileUtils.rm_rf('.chef/local-mode-cache')
    FileUtils.rm_rf('cookbooks/')
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
    puts 'Delivery Server'.yellow
    puts File.read(Dir['.chef/delivery-cluster-data/*.creds'].first)
    puts "\nChef Server".yellow
    puts 'Username: delivery'
    puts 'Password: delivery'
    system 'grep chef_server_url .chef/delivery-cluster-data/knife.rb'
  end

  desc 'List all your core services'
  task :list_core_services do
    system 'knife search node \'name:*server* OR name:build-node*\' -a ipaddress'
    system 'grep chef_server_url .chef/delivery-cluster-data/knife.rb'
  end
end

task default: [:help]
task :help do
  puts "\nDelivery Cluster Helper".green
  puts "\nSetup Tasks".pink
  puts 'The following tasks should be used to set up your cluster'.yellow
  Rake.application.options.show_tasks = :tasks # this solves sidewaysmilk problem
  Rake.application.options.show_task_pattern = /setup/
  Rake.application.display_tasks_and_comments
  puts "\nMaintenance Tasks".pink
  puts 'The following tasks should be used to maintain your cluster'.yellow
  Rake.application.options.show_task_pattern = /maintenance/
  Rake.application.display_tasks_and_comments
  puts "\nDestroy Tasks".pink
  puts 'The following tasks should be used to destroy your cluster'.yellow
  Rake.application.options.show_task_pattern = /destroy/
  Rake.application.display_tasks_and_comments
  puts "\nCluster Information".pink
  puts 'The following tasks should be used to get information about your cluster'.yellow
  Rake.application.options.show_task_pattern = /info/
  Rake.application.display_tasks_and_comments
  puts "\nTo switch your environment run:"
  puts "  # export CHEF_ENV=#{'my_environment_name'.yellow}\n"
end
