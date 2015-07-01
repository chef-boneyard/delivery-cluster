v0.3.2 (2015-07-1)
-------------------
- [#140] Fix Supermarket Setup

v0.3.1 (2015-06-30)
-------------------
- Expose chef_version to drivers

v0.3.0 (2015-06-29)
-------------------
- Create CHANGELOG.md
- Set default driver to Vagrant
- Add chefspec for destroy_all recipe
- Add chefspecs for Vagrant Library
- Add chefspecs for AWS Library
- Add chefspec for setup recipe
- Add chefspecs for SSH Library
- Bump chef-provisioning version 1.3.0
- Install chef-provisioning drivers into build-cookbook:default
- Add vagrant driver and rake tasks for vagrant driver

v0.2.29 (2015-06-11)
-------------------
- Change chef-zero port to 8890 & enable opscode-reporting
- Fix recursive loop call when generate environments
- Add new library cookbook delivery-sugar-extras

v0.2.27 (2015-06-05)
-------------------
- Introduce delivery-red-pill cookbook to implement matrix builds
- Only destroy splunk server if enabled
- Fix destroy process of build nodes
- Add delivery-sugar dependency
- Upgrade process (Documentation)

v0.2.22 (2015-05-26)
-------------------
- Run delivery-ctl reconfigure after a delivery upgrade
- Consume delivery-truck default recipe
- Add build cookbook
- Add Delivery config.json

v0.2.19 (2015-05-20)
-------------------
- [#124] Move the reporting enable/disable into an attribute
- [#123] Install stable delivery packages instead of bleeding edge
- [#122] Use node.hostname instead of node.name
- [#121] Add chef server hostname to /etc/hosts

v0.2.17 (2015-05-13)
-------------------
- [#119] Update berkshelf to 3.2.4

v0.2.16 (2015-05-12)
-------------------
- [#116] Remove delivery_build cookbook
- [#114] Easy Setup Documentation
- [#112] Better Cluster data cleanup
- [#111] Add recipe back into setup_chef_server
- [#109] Make run_lists attributes; Separate setup_delivery

v0.2.11 (2015-05-07)
-------------------
- Abstract node methods by Component
- Abstract hostname methods by Component
- Abstract FQDN methods by Component
- [#107] Honor host instead of ip
- [#106] Rename methods to say FQDN instead of IP
- [#104] Fix pulling down from Artifactory
- [#102] Fix Analytics Attributes

v0.2.7 (2015-05-02)
-------------------
- [#95] Supermarket Component
- Use Analytics FQDN instead of IP Address
- Make delivery-cluster consume latest builds from packagecloud

v0.2.3 (2015-04-22)
-------------------
- Disable opscode-reporting

v0.2.2 (2015-04-21)
-------------------
- Install delivery-cli from artifact url

v0.2.0 (2015-04-17)
-------------------
- Support for Delivery License Key
- Splunk Server Component
- Splunk Integration
- Analytics Server Component

v0.1.0 (2015-01-23)
-------------------
- Initial commit


```text
Copyright:: 2015 Chef Software, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
