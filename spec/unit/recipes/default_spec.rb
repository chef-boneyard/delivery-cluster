require 'spec_helper'

describe "delivery-cluster::default" do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      platform: 'redhat',
      version: '6.3',
      log_level: :error
    )
    runner.converge('recipe[delivery-cluster::default]')
  end

  # TODO: Write some tests
end
