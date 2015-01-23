require 'spec_helper'

describe "delivery-server::default" do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      platform: 'redhat',
      version: '6.3',
      log_level: :error
    )
    runner.converge('recipe[delivery-server::default]')
  end
  
  # TODO: Write some tests
end