class Chef
  class Provider
    class DeliveryWaitForStage < Chef::Provider::LWRPBase
      provides :delivery_wait_for_stage

      use_inline_resources

      action :wait do
        converge_by("Wait for stage: #{stage} to complete for change: #{change_id}") do
          new_resource.updated_by_last_action(wait_for_stage)
        end
      end

      private

      def change_id
        @change_id ||= new_resource.change_id
      end

      def stage
        @stage ||= new_resource.stage
      end

      def fail_run
        @fail_run ||= new_resource.fail_run
      end

      def wait_for_stage
        status = ::DeliveryMatrix::Helpers.wait_for_stage_completion(node, stage, change_id)

        if status == 'failed' && fail_run
          ::Chef::Log.error("\n")
          ::Chef::Log.error("Stage: #{stage} failed for change: #{change_id}")
          ::Chef::Log.error("    #{build_web_url}")
          raise "Stage: #{stage} failed for change: #{change_id}"
        end
      end

      def build_web_url
        api_uri = URI.parse(node['delivery']['change']['delivery_api_url'])
        path = ::File.join(node['delivery']['change']['enterprise'], '#',
                           'organizations', node['delivery']['change']['organization'],
                           'projects', node['delivery']['change']['project'],
                           'changes', change_id)
        "#{api_uri.scheme}://#{api_uri.host}/e/#{path}"
      end
    end
  end
end

class Chef
  class Resource
    class DeliveryWaitForStage < Chef::Resource::LWRPBase
      actions :wait

      # TODO: Wait for finish and wait for start?
      default_action :wait

      attribute :change_id, :kind_of => String, :name_attribute => true, :required => true
      attribute :stage, :kind_of => String, :required => true
      attribute :fail_run, :kind_of => [ TrueClass, FalseClass ], :default => true

      self.resource_name = :delivery_wait_for_stage

      def initialize(name, run_context=nil)
        super
        @provider = Chef::Provider::DeliveryWaitForStage
      end
    end
  end
end
