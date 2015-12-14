#
# Cookbook Name:: delivery-cluster
# Library:: artifactory_helper
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

require 'net/http'
require 'chef/application'

# Artifact Helper
#
# Get the latest artifact without downloading the artifact:
# => artifact = get_delivery_artifact(node, 'latest', 'redhat', '6.5')
#
# Get specific artifact and also download the artifact locally:
# => artifact = get_delivery_artifact(node, '0.2.21', 'ubuntu', '12.04', '/var/tmp')
#
# Will Return:
# {
#   'name' => "delivery-0.1.0-alpha.132+20141126080809-1.x86_64.rpm",
#   'version' => "0.1.0-alpha.132",
#   'checksum' => "ee79c56bcbd20bbe4ba841736482fa59",
#   'uri' => "http://artifactory.chef.co/omnibus-current-local/com/getchef/delivery/0.1.0-alpha.132+20141126080809/el/6/delivery-0.1.0_alpha.132+20141126080809-1.x86_64.rpm",
#   'local_path' => "/tmp/delivery-0.1.0-alpha.132+20141126080809-1.x86_64.rpm"
# }
#
# NOTE: If you do not specify a `tmp_dir` it will not download the artifact
#       so there will be no `local_path` in the returned value
def get_delivery_artifact(node, version = 'latest', platform = 'ubuntu', platform_version = '14.04', tmp_dir = nil)
  # Yup! We must validate access to Chef VPN
  Chef::Application.fatal! 'You need to connect to the VPN to build your delivery-cluster!' unless validate_vpn

  artifactory_gem = Chef::Resource::ChefGem.new('artifactory', node.run_context)
  artifactory_gem.run_action(:install)
  require 'artifactory'

  artifactory_endpoint     = 'http://artifactory.chef.co'
  artifactory_omnibus_repo = 'omnibus-current-local'

  # Create an anonymous client
  client = Artifactory::Client.new(
    endpoint: artifactory_endpoint
  )

  deliv_version = version

  # If we need the latest version, lets get it from artifactory
  if version.eql?('latest')
    deliv_version = client.artifact_latest_version(
      repos: artifactory_omnibus_repo,
      group: 'com.getchef',
      name: 'delivery'
    )
  end

  supported = supported_platforms_format(platform, platform_version)

  artifact = client.artifact_property_search(
    'omnibus.platform' => supported['platform'],
    'omnibus.platform_version' => supported['version'],
    'omnibus.project' => 'delivery',
    'omnibus.version' => deliv_version
  ).first

  # If we specify a temporal directoy we will download the artifact
  # otherwise we will return NO `local_path` attribute
  local_path = {}
  if tmp_dir
    latest_delivery = "#{tmp_dir}/#{File.basename(artifact.uri)}"

    remote_file = Chef::Resource::RemoteFile.new(latest_delivery, node.run_context)
    remote_file.source(artifact.download_uri)
    remote_file.run_action(:create)

    local_path = { 'local_path' => "#{tmp_dir}/#{File.basename(artifact.uri)}" }
  end

  {
    'name' => File.basename(artifact.uri),
    'version' => deliv_version.split('+')[0],
    'checksum' => artifact.properties['omnibus.sha256'].first,
    'uri' => artifact.download_uri
  }.merge(local_path)
end

def supported_platforms_format(platform, platform_version)
  case platform
  when 'centos', 'redhat'
    case platform_version.to_s
    when '6', '6.1', '6.2', '6.3', '6.4', '6.5', '6.6'
      {
        'platform' => 'el',
        'version' => '6'
      }
    else
      Chef::Application.fatal!("Unsupported Platform Version: #{platform_version}")
    end
  when 'ubuntu'
    if platform_version.to_s == '12.04' || platform_version.to_s == '14.04'
      {
        'platform' => 'ubuntu',
        'version' => platform_version
      }
    else
      Chef::Application.fatal!("Unsupported Platform Version: #{platform_version}")
    end
  else
    Chef::Application.fatal!("Unsupported Platform: #{platform}")
  end
end

# When we need to reach out Chef Artifactory we must ensure that we are
# connected to the Chef VPN. Otherwise we don't go any further.
def validate_vpn
  http = ::Net::HTTP.new 'artifactory.chef.co'
  http.open_timeout = 5

  begin
    http.get '/'
  rescue ::Timeout::Error
    false
  end
end
