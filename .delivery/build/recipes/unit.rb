include_recipe 'delivery-truck::unit'

ruby_block "set_rs" do
  block do
    node.run_state['delivery'] = {} if !node.run_state['delivery']
    node.run_state['delivery']['change'] = {} if !node.run_state['delivery']['change']
    node.run_state['delivery']['change']['data'] = {} if !node.run_state['delivery']['change']['data']
    node.run_state['delivery']['change']['data']['test'] = {} if !node.run_state['delivery']['change']['data']['spawned_changes']
    node.run_state['delivery']['change']['data']['test']['pipeline'] = 'test' ## Clean up wierd trailing char
  end
end

delivery_change_db node['delivery']['change']['change_id']

ruby_block "unset_rs" do
  block do
    node.run_state['delivery'] = {}
  end
end

log "log unset rs" do
  message lazy {"RS: #{node.run_state['delivery']}"}
  level :warn
end

delivery_change_db node['delivery']['change']['change_id'] do
  action :download
end

log "log rs" do
  message lazy {"RS: #{node.run_state['delivery']}"}
  level :warn
end
