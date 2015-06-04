module DeliveryRedPill
  module Helpers
    extend self

    def add_all_change_data_to_node(node)
      change_file = ::File.read(::File.join("/var/opt/delivery/workspace/", 'change.json'))
      change_hash = ::JSON.parse(change_file)
      node.set['delivery']['change'].merge!(change_hash)
    end

    def git_ssh
      ::File.join('/var/opt/delivery/workspace/bin', 'git_ssh')
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

      ::Chef_Delivery::ClientHelper.enter_client_mode_as_delivery
      headers = delivery_api_auth_headers(node)
      headers["Content-Type"] = 'application/json'
      resp = client.post(path, data, headers)
      ::Chef_Delivery::ClientHelper.leave_client_mode_as_delivery
      resp
    end

    def delivery_api_get(node, path)
      client = delivery_api_client(node)

      ::Chef_Delivery::ClientHelper.enter_client_mode_as_delivery
      resp = client.get(path, delivery_api_auth_headers(node))
      ::Chef_Delivery::ClientHelper.leave_client_mode_as_delivery
      resp
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
