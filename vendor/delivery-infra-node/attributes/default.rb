#
# Copyright 2015 Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_attribute 'push-jobs'

case node['platform_family']
when 'rhel'
  default['push_jobs']['package_url']      = 'https://opscode-private-chef.s3.amazonaws.com/el/6/x86_64/opscode-push-jobs-client-1.1.5-1.el6.x86_64.rpm'
  default['push_jobs']['package_checksum'] = 'f5e6be32f60b689e999dcdceb102371a4ab21e5a1bb6fb69ff4b2243a7185d84'
when 'debian'
  default['push_jobs']['package_url']      = 'http://sales-at-getchef-dot-com.s3.amazonaws.com/opscode-push-jobs-client_1.0.1-1.ubuntu.12.04_amd64.deb'
  default['push_jobs']['package_checksum'] = '72ad9b23e058391e8dd1eaa5ba2c8af1a6b8a6c5061c6d28ee2c427826283492'
when 'windows'
  default['push_jobs']['package_url']      = 'https://opscode-private-chef.s3.amazonaws.com/windows/2008r2/x86_64/opscode-push-jobs-client-windows-1.1.5-1.windows.msi'
  default['push_jobs']['package_checksum'] = '411520e6a2e3038cd018ffacee0e76e37e7badd1aa84de03f5469c19e8d6c576'
end
