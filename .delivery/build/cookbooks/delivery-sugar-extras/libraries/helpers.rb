module DeliverySugarExtras
  module Helpers
    extend self

    def add_all_change_data_to_node(node)
      change_file = ::File.read(::File.join("/var/opt/delivery/workspace/", 'change.json'))
      change_hash = ::JSON.parse(change_file)
      node.set['delivery']['change'].merge!(change_hash)
    end
  end
end
