# Artifact Helper
#
# Get the latest artifact: 
# => artifact = get_delivery_artifact('latest', 'redhat', '6.5')
#
# Get specific artifact: 
# => artifact = get_delivery_artifact('0.2.21', 'ubuntu', '12.04', '/var/tmp')
#
# Will Return:
# {
#   'name' => "delivery-0.1.0-alpha.132+20141126080809-1.x86_64.rpm",
#   'version' => "0.1.0-alpha.132",
#   'checksum' => "ee79c56bcbd20bbe4ba841736482fa59",
#   'uri' => "http://artifactory.chef.co/omnibus-current-local/com/getchef/delivery/0.1.0-alpha.132+20141126080809/el/6/delivery-0.1.0_alpha.132+20141126080809-1.x86_64.rpm",
#   'local_path' => "/tmp/delivery-0.1.0-alpha.132+20141126080809-1.x86_64.rpm"
# }
def get_delivery_artifact(version = 'latest', platform = 'ubuntu', platform_version = '14.04', tmp_dir = '/tmp')

	# Yup! We must validate access to Chef VPN
	validate_vpn
	
	chef_gem 'artifactory'
	require 'artifactory'

	artifactory_endpoint     = 'http://artifactory.chef.co'
	artifactory_omnibus_repo = 'omnibus-current-local'

	# Create an anonymous client
	client = Artifactory::Client.new(
	  endpoint: artifactory_endpoint
	)

	deliv_version = client.artifact_latest_version(
	  repos: artifactory_omnibus_repo,
	  group: 'com.getchef',
	  name: 'delivery',
	  version: version == 'latest' ? '*' : version
	)

  supported = supported_platforms_format(platform, platform_version)

	artifact = client.artifact_property_search(
	  'omnibus.platform' => supported['platform'],
	  'omnibus.platform_version' => supported['version'],
	  'omnibus.project' => 'delivery',
	  'omnibus.version' => deliv_version
	).first

	latest_delivery = "#{tmp_dir}/#{File.basename(artifact.uri)}"

	remote_file latest_delivery do
	  source artifact.download_uri
	end

  {
    'name' => File.basename(artifact.uri),
    'version' => deliv_version.split('+')[0],
    'checksum' => artifact.checksums['md5'],
    'uri' => artifact.download_uri,
    'local_path' => "#{tmp_dir}/#{File.basename(artifact.uri)}"
  }

end

def supported_platforms_format(platform, platform_version)
  case platform
  when 'centos', 'redhat' 
    case platform_version.to_s
    when "6", "6.1", "6.2", "6.3", "6.4", "6.5"
      {
        'platform' => 'el',
        'version' => '6'
      }
    else  
      Chef::Log.fatal("Unsupported Platform Version: #{platform_version}")
    end
  when 'ubuntu'
    if platform_version.to_s == "12.04" || platform_version.to_s == "14.04"
      {
        'platform' => 'ubuntu',
        'version' => platform_version
      }
    else
      Chef::Log.fatal("Unsupported Platform Version: #{platform_version}")
    end
  else
    Chef::Log.fatal("Unsupported Platform: #{platform}")
  end
end

# TODO: 
def validate_vpn
  puts "TODO: Validate VPN"
end
