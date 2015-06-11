class Chef
  class Provider
    class DeliveryChangeDb < Chef::Provider::LWRPBase
      provides :delivery_change_db

      use_inline_resources

      action :create do
        converge_by("Create Change Databag Item: #{change_id}") do
          new_resource.updated_by_last_action(create_databag)
        end
      end

      action :download do
        converge_by("Downloading Change Databag Item: #{change_id} to node.run_state['delivery']['change']['data']") do
          new_resource.updated_by_last_action(download_databag)
        end
      end

      private

      def change_id
        @change_id ||= new_resource.change_id
      end

      def create_databag
        # Create the data bag
        begin
          bag = Chef::DataBag.new
          bag.name(db_name)

          DeliverySugar::ChefServer.new.with_server_config do
            bag.create
          end
        rescue Net::HTTPServerException => e
          if e.response.code == "409"
            ::Chef::Log.info("DataBag changes already exists.")
          else
            raise
          end
        end

        dbi_hash = {
          "id"       => change_id,
          "data" => node.run_state['delivery']['change']['data']
        }

        ## TODO: Merge instead of always creating a new one?
        bag_item = Chef::DataBagItem.new
        bag_item.data_bag(db_name)
        bag_item.raw_data = dbi_hash

        DeliverySugar::ChefServer.new.with_server_config do
          bag_item.save
        end
        ::Chef::Log.info("Saved bag item #{dbi_hash} in data bag #{change_id}.")
      end

      def download_databag
        ## TODO: Look at new delivery-truck syntax
        dbi = DeliverySugar::ChefServer.new.with_server_config do
          data_bag_item(db_name, change_id)
        end

        node.run_state['delivery'] ||= {}
        node.run_state['delivery']['change'] ||= {}
        node.run_state['delivery']['change']['data'] ||= dbi['data']
      end

      def db_name
        'delivery_changes'
      end
    end
  end
end

class Chef
  class Resource
    class DeliveryChangeDb < Chef::Resource::LWRPBase
      actions :create, :download

      default_action :create

      attribute :change_id, :kind_of => String, :name_attribute => true, :required => true

      self.resource_name = :delivery_change_db

      def initialize(name, run_context=nil)
        super
        @provider = Chef::Provider::DeliveryChangeDb
      end
    end
  end
end
