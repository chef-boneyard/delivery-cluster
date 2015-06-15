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

      ## Note the version here. We are appending '-1' because artifactory
      ## returns the version as 0.3.73 in the outer versions call even though
      ## the artifact is 0.3.37-1. We'd have to make an additional call for
      ## each to get the version with '-1'. We should never have anything other
      ## than '-1' so we are encuring a bit of calculated risk here for the sake
      ## of not having to call multiple apis.
      client.get('/api/search/versions',
        repos: 'omnibus-stable-local',
        g: 'com.getchef',
        a: 'delivery')['results'].map { |e| "#{e["version"]}-1" }
    end
  end
end
