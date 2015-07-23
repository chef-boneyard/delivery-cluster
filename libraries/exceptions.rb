#
# Cookbook Name:: delivery-cluster
# Library:: helpers_component
#
# Author:: Salim Afiune (<afiune@chef.io>)
#
# Copyright:: Copyright (c) 2015 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module DeliveryCluster
  class Exceptions
    #
    # Raise when we couldn't found an specific attribute
    #
    class AttributeNotFound < RuntimeError
      attr_reader :attr

      def initialize(attr)
        @attr = attr
      end

      def to_s
        "Attribute '#{@attr}' not found"
      end
    end

    #
    # Raise when there was no License File specified
    #
    class LicenseNotFound < RuntimeError
      attr_reader :attr

      def initialize(attr)
        @attr = attr
      end

      def to_s
        <<-EOM.gsub(/^ {10}/, '')

          ***************************************************

          Chef Delivery requires a valid license to run.
          To acquire a license, please contact your CHEF
          account representative.

          Please set `#{@attr}`
          in your environment file.

          ***************************************************
        EOM
      end
    end
  end
end
