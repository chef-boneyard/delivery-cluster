#
# Cookbook Name:: build
# Recipe:: _smoke
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

delivery_stage_db do
  action :download
end

delivery_server_url = 'delivery.chef.co'
delivery_version = '0.3.76'
chef_server_url = 'chef-server.delivery.chef.co'
#build_nodes = ['10.194.11.67']

delivery_rspec_block "Smoke Test Delivery Cluster" do
  block do
    require 'watir-webdriver'
    require 'phantomjs'

    # This sets the phantomjs path since it is being installed
    # in the build cache i.e. build user's home dir by the
    # phantomjs gem when we need it.
    ::Selenium::WebDriver::PhantomJS.path = Phantomjs.path

    # Configuration for watir-rspec
    RSpec.configure do |config|
      # Open up the browser for each example.
      config.before :all do
        @browser = ::Watir::Browser.new :phantomjs, :args => ['--ignore-ssl-errors=yes']
      end

      # Close that browser after each example.
      config.after :all do
        @browser.close if @browser
      end
    end

    servers = node.run_state['delivery']['stage']['data']['servers']

    describe 'Chef Server' do
      before { @browser.goto "http:://#{servers['chef_server']}" }

      it "login page is available" do
        expect(@browser.url).not_to eql("about:blank")
      end
    end

    describe 'Delivery Server' do
      it "deployed version is #{delivery_version}" do
        @browser.goto "#{servers['delivery_server']}/status/version"
        expect(@browser.text).to include("delivery #{delivery_version}")
      end

      it "login page is available" do
        @browser.goto servers['delivery_server']
        expect(@browser.url).not_to eql("about:blank")
      end
    end
  end
end
