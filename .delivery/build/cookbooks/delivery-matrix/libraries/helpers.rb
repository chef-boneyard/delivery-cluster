module DeliveryMatrix
  module Helpers
    include Chef::Mixin::ShellOut
    extend self

    def add_all_change_data_to_node(node)
      change_file = ::File.read(::File.join("/var/opt/delivery/workspace/", 'change.json'))
      change_hash = ::JSON.parse(change_file)
      node.set['delivery']['change'].merge!(change_hash)
    end

    def git_ssh
      ::File.join('/var/opt/delivery/workspace/bin', 'git_ssh')
    end

    # Return the SHA for the point in our history where we split off. For verify
    # this will be HEAD on the pipeline branch. For later stages, because HEAD
    # on the pipeline branch is our change, we will look for the 2nd most recent
    # commit to the pipeline branch.
    #
    # @param [Chef::Node] Chef Node object
    # @return [String]
    def pre_change_sha(node)
      workspace = node['delivery']['workspace']['repo']
      branch1 = node['delivery']['change']['pipeline']
      branch2 = node['delivery']['change']['patchset_branch']

      ## If we have a merge sha we need to get the commit before the merge
      ## otherwise merge-base == HEAD
      if node['delivery']['change']['sha']
        branch2 = "#{node['delivery']['change']['sha']}~1"
      end

      shell_out("git merge-base #{branch1} #{branch2}", cwd: workspace)
               .stdout.chomp
    end

    def wait_for_stage_completion(node, stage, change_id)
      ## Wait for completion of stage.
      status = 'idle'

      begin
        change_resp = delivery_api_get_change(node, change_id)
        change_hash = JSON.parse(change_resp)

        stage_run_data = change_hash['stages'].detect do |s|
          s['stage'] == stage
        end

        if stage_run_data
          status = stage_run_data['status']
        end
        sleep 15 if status != 'passed' && status != 'failed'
      end while status != 'passed' && status != 'failed'

      status
    end

    def delivery_api_auth_headers(node)
      add_all_change_data_to_node(node)
      {"chef-delivery-token" => node['delivery']['change']['token'],
       "chef-delivery-user"  => 'builder'}
    end

    def delivery_api_client(node)
      add_all_change_data_to_node(node)
      ::Chef::HTTP.new(node['delivery']['change']['delivery_api_url'])
    end

    def delivery_api_post(node, path, data)
      client = delivery_api_client(node)

      headers = delivery_api_auth_headers(node)
      headers["Content-Type"] = 'application/json'
      DeliverySugar::ChefServer.new.with_server_config do
        client.post(path, data, headers)
      end
    end

    def delivery_api_get(node, path)
      client = delivery_api_client(node)

      DeliverySugar::ChefServer.new.with_server_config do
        client.get(path, delivery_api_auth_headers(node))
      end
    end

    def delivery_api_create_pipeline(node, name, base)
      path = ::File.join(node['delivery']['change']['enterprise'],
                         'orgs', node['delivery']['change']['organization'],
                         'projects', node['delivery']['change']['project'],
                         'pipelines')
      data = {"name" => name, "base" => base}

      delivery_api_post(node, path, data.to_json)
    end

    def delivery_api_get_change(node, change_id)
      path = ::File.join(node['delivery']['change']['enterprise'],
                         'orgs', node['delivery']['change']['organization'],
                         'projects', node['delivery']['change']['project'],
                         'changes', change_id)

      delivery_api_get(node, path)
    end

    def delivery_api_merge_change(node, change_id)
      path = ::File.join(node['delivery']['change']['enterprise'],
                         'orgs', node['delivery']['change']['organization'],
                         'projects', node['delivery']['change']['project'],
                         'changes', change_id, 'merge')

      delivery_api_post(node, path, "{}")
    end
  end
end
