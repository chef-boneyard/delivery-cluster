require 'chef/chef_fs/parallelizer'
require 'chef/provider/lwrp_base'
require 'chef/resource/lwrp_base'

class Chef
  class Provider
    class DeliveryInParallel < Chef::Provider::LWRPBase
      provides :delivery_in_parallel

      def whyrun_supported?
        true
      end

      def parallelizer
        @parallelizer ||= Chef::ChefFS::Parallelizer.new(max_simultaneous || 100)
      end

      def max_simultaneous
        @max_simultaneous ||= new_resource.max_simultaneous
      end

      action :run do
        parallel_do(new_resource.block_resources) do |resource|
          Array(resource.action).each {|action| resource.run_action(action)}
        end
      end

      def parallel_do(enum, options = {}, &block)
        parallelizer.parallelize(enum, options, &block).to_a
      end
    end
  end
end

class Chef
  class Resource
    class DeliveryInParallel < Chef::Resource::LWRPBase
      actions :run
      default_action :run

      attribute :block_resources, :kind_of => [ Array ]
      attribute :from_recipe
      attribute :max_simultaneous, :kind_of => [ Integer ]

      self.resource_name = :delivery_in_parallel

      def initialize(name, run_context=nil)
        super
        @block_resources = []
        @provider = Chef::Provider::DeliveryInParallel
      end

      alias_method :old_method_missing, :method_missing

      def method_missing(m, *args, &block)
	      old_method_missing(m, *args, &block)
      rescue NoMethodError
        block_resources << from_recipe.build_resource(m, args[0], caller[0], &block)
      end
    end
  end
end

class Chef
  module DSL
    module Recipe
      @@next_delivery_in_parallel_index = 0

      def delivery_in_parallel_name
        @@next_delivery_in_parallel_index += 1
        if @@next_delivery_in_parallel_index > 1
          "default#{@@next_delivery_in_parallel_index}"
        else
          "default"
        end
      end

      def delivery_in_parallel(name = nil, &block)
        name ||= delivery_in_parallel_name
        recipe = self
        declare_resource(:delivery_in_parallel, name, caller[0]) do
          from_recipe recipe
          instance_eval(&block)
        end
      end
    end
  end
end
