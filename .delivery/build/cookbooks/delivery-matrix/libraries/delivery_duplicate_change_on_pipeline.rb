class Chef
  class Provider
    class DeliveryDuplicateChangeOnPipeline < Chef::Provider::LWRPBase
      require 'thread'
      @@semaphore = Mutex.new

      provides :delivery_duplicate_change_on_pipeline

      use_inline_resources

      def whyrun_supported?
        true
      end

      def pipeline
        @pipeline ||= new_resource.pipeline
      end

      def auto_approve
        @auto_approve ||= new_resource.auto_approve
      end

      action :duplicate do
        converge_by("Duplicating change on #{pipeline}") do
          new_resource.updated_by_last_action(duplicate)
        end
      end

      def duplicate
        create_pipeline(node)

        ### Duplicate change on pipelines
        #### Add delivery remote do delivery cli will work.
        add_delivery_remote(node)
        change_web_url = @@semaphore.synchronize do
          create_change_on_pipeline(node)
        end
        change_id = change_web_url.split('/').last

        if auto_approve
          verify_status = ::DeliveryMatrix::Helpers.wait_for_stage_completion(node, 'verify', change_id)
          if verify_status == 'passed'
            ::DeliveryMatrix::Helpers.delivery_api_merge_change(node, change_id)
          else
            ::Chef::Log.error("Verify failed for change: #{change_id} on pipeline: #{pipeline}.")
            ::Chef::Log.error("    #{change_web_url}")
            raise
          end
        end

        node.run_state['delivery'] ||= {}
        node.run_state['delivery']['change'] ||= {}
        node.run_state['delivery']['change']['data'] ||= {}
        node.run_state['delivery']['change']['data']['spawned_changes'] ||= {}
        node.run_state['delivery']['change']['data']['spawned_changes'][pipeline] ||= change_id.split("%")[0] ## Clean up wierd trailing char
      end

      def create_pipeline(node)
        base = ::DeliveryMatrix::Helpers.pre_change_sha(node)
        begin
          ::DeliveryMatrix::Helpers.delivery_api_create_pipeline(node, pipeline, base)
        rescue Net::HTTPServerException => hse
          ## So if we get a 400 it means the pipeline exists but delivery is stupid
          ## and deletes the underlying branch. We need to re-call create pipeline
          ## in which case delivery will return 409 conflict but re-create the branch.
          if hse.response.code == '400'
            create_pipeline(node)
          elsif hse.response.code == '409'
            ## Pipeline exists return
            return
          else
            raise
          end
        end
      end

      def add_delivery_remote(node)
        git_remote_add = Mixlib::ShellOut.new("git remote add delivery `git config --get remote.origin.url`",
                                              :env => {"GIT_SSH" => git_ssh},
                                              :cwd => node['delivery']['workspace']['repo'],
                                              :returns => [0,128])

        git_remote_add.run_command
      end

      def create_change_on_pipeline(node)
        delivery_review = Mixlib::ShellOut.new("delivery review --for=#{pipeline} --no-open",
                                               :env => {"GIT_SSH" => git_ssh},
                                               :cwd => node['delivery']['workspace']['repo'])

        delivery_review.run_command

        if delivery_review.stdout && delivery_review.stdout[-2]
          raw_url = delivery_review.stdout.lines[-2]
          stripped_url = URI.escape(raw_url.chomp.gsub(/\e\[K|\e\(B|\e\[\d+m/,''))
          ## Check that it is a url.
          if stripped_url =~ URI::regexp
            change_id = stripped_url.split('/').last
            ::Chef::Log.info("Created change: #{change_id} on pipeline: #{pipeline}.")
            ::Chef::Log.info("    #{stripped_url}")
            stripped_url
          else
            ::Chef::Log.error("Failed to create duplicate change.")
            raise "Failed to create duplicate change."
          end
        end
      end

      def git_ssh
        ::File.join('/var/opt/delivery/workspace/bin', 'git_ssh')
      end
    end
  end
end

class Chef
  class Resource
    class DeliveryDuplicateChangeOnPipeline < Chef::Resource::LWRPBase
      actions :duplicate
      default_action :duplicate

      attribute :pipeline, :kind_of => [ String ], :name_attribute => true, :required => true
      attribute :auto_approve, :kind_of =>  [ TrueClass, FalseClass ]

      self.resource_name = :delivery_duplicate_change_on_pipeline

      def initialize(name, run_context=nil)
        super
        @provider = Chef::Provider::DeliveryDuplicateChangeOnPipeline
      end
    end
  end
end
