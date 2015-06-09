require 'chef/provider/lwrp_base'
require 'chef/resource/lwrp_base'

class Chef
  class Provider
    class DeliveryRspecBlock < Chef::Provider::LWRPBase
      require 'rspec'

      provides :delivery_rspec_block

      action :run do
        converge_by("execute the rspec block #{name}") do
          new_resource.updated_by_last_action(run_rspec_block &block)
        end
      end

      private

      def name
        @name ||= new_resource.name
      end

      def block
        @block ||= new_resource.block
      end

      def run_rspec_block
        RSpec.example_group &block
        #block.call
        rspec_opts = RSpec::Core::ConfigurationOptions.new([])
        runner = RSpec::Core::Runner.new(rspec_opts)
        exit_code = runner.run($stderr, $stdout)
        raise "One or more tests failed!" if exit_code > 0
      end

    end
  end
end

class Chef
  class Resource
    class DeliveryRspecBlock < Chef::Resource::LWRPBase

      actions :run
      default_action :run

      self.resource_name = :delivery_rspec_block

      def initialize(name, run_context=nil)
        super
        @provider = Chef::Provider::DeliveryRspecBlock
      end

      def block(&block)
        if block_given? and block
          @block = block
        else
          @block
        end
      end

    end
  end
end

class Chef
  module DSL
    module Recipe
      @@next_delivery_rspec_block_index = 0

      def delivery_rspec_block_name
        @@next_delivery_rspec_block_index += 1
        if @@next_delivery_rspec_block_index > 1
          "default#{@@next_delivery_rspec_block_index}"
        else
          "default"
        end
      end

      def delivery_rspec_block(name = nil, &block)
        name ||= delivery_rspec_block_name
        declare_resource(:delivery_rspec_block, name, caller[0]) do
          instance_eval(&block)
        end
      end
    end
  end
end
