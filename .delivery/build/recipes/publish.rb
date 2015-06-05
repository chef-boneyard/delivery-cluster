if node['delivery']['change']['pipeline'] == 'master'
  include_recipe 'delivery-truck::publish'
end
