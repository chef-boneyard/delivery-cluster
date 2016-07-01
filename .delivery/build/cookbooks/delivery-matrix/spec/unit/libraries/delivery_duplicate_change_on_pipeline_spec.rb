require 'spec_helper'
require 'chef/run_context'
require 'chef/node'
require_relative '../../../libraries/delivery_duplicate_change_on_pipeline.rb'

describe Chef::Provider::DeliveryDuplicateChangeOnPipeline do
  let(:run_context) { Chef::RunContext.new(Chef::Node.new, [], nil) }
  let(:subject) { Chef::Provider::DeliveryDuplicateChangeOnPipeline.new("foo", run_context) }
  let(:http_url) { "http://delivery.chef.co/foobar" }
  let(:https_url) { "http://delivery.chef.co/foobar" }

  context "#url_from_delivery_review" do
    it "recognizes http addresses" do
      output = "#{http_url}\nanother_line\n"
      expect(subject.url_from_review_output(output)).to eq(http_url)
    end

    it "recognizes https addresses" do
      output = "#{https_url}\nanother_line\n"
      expect(subject.url_from_review_output(output)).to eq(https_url)
    end

    it "ignores ansi escape codes before the url" do
      output = "\e[33m#{https_url}\nanother_line\n"
      expect(subject.url_from_review_output(output)).to eq(https_url)
    end

    it "ignores ansi escape codes after the url" do
      output = "\e[35m#{https_url}\e[35m\nanother_line\n"
      expect(subject.url_from_review_output(output)).to eq(https_url)
    end

    it "ignores TERM=screen sgr0" do
      output = "\e[35m#{https_url}\e[m\u000F\e[35m\nanother_line\n"
      expect(subject.url_from_review_output(output)).to eq(https_url)
    end

    it "ignores TERM=xterm sgr0" do
      output = "\e[35m#{https_url}\e(B\e[m\e[35m\nanother_line\n"
      expect(subject.url_from_review_output(output)).to eq(https_url)
    end

    it "ignores TERM=linux sgr0" do
      output = "\e[35m#{https_url}\e[0;10m\e[35m\nanother_line\n"
      expect(subject.url_from_review_output(output)).to eq(https_url)
    end

    it "raises an error if it can't parse a url" do
      output = "not_a_url\nalso_not_a_url"
      expect{subject.url_from_review_output(output)}.to raise_error(RuntimeError)
    end
  end
end
