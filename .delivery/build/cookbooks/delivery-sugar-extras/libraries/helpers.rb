module DeliverySugarExtras
  module Helpers
    extend self

    def add_all_change_data_to_node(node)
      change_file = ::File.read(::File.join("/var/opt/delivery/workspace/", 'change.json'))
      change_hash = ::JSON.parse(change_file)
      node.set['delivery']['change'].merge!(change_hash)
    end

    def get_delivery_versions(node)
      require 'artifactory'
      
      client = Artifactory::Client.new(
        endpoint: 'http://artifactory.opscode.us',
      )

      client.get('/api/search/versions',
        repos: 'omnibus-stable-local',
        g: 'com.getchef',
        a: 'delivery')['results'].map { |e| e["version"] }
    end
  end
end
