v0.5.2 (2015-12-30)
-------------------
- [#175] Allow passing extra attributes to components
- [#183] Vefiry ChefDK version and Install Prerequisites
- Get rid of `bundle` in favor of ChefDK
- Rename delivery-red-pill cookbook to delivery-matrix (build-cookbook)
- Updated chef-provisioning-aws to 1.7.0
- Updated delivery_build to 0.4.9
- Add dependency to build-essentials (build-cookbook)

v0.4.0 (2015-11-13)
-------------------
- Remove packagecloud dependency in favor of chef-ingredient

v0.3.30 (2015-11-06)
-------------------
- Enable Supermarket in the Pipeline
- Wrap activate_supermarket in a ruby_block
- Include Supermarket in setup cluster
- Remove delivery-cli artifact question in Rake
- Set mode to 0644 on delivery.license
- Bundle update chef-provisioning-aws to 1.6.0
- Fixing the pipeline with chef-ingredient 0.12.0
- Adopt delivery-base and update dependencies
- Ensure all files get uploaded to the build-nodes
- Pipeline improvements

v0.3.20 (2015-09-30)
-------------------
- Enabled `aws_tags` for AWS Driver
- Fixed conflict using `bundler` inside `chefdk`
- Update gem dependencies
  - chef (12.4.3)
  - chef-provisioning (~> 1.4)
  - chef-provisioning-aws (1.4.1)
  - chef-provisioning-ssh (0.0.9)
  - chef-provisioning-vagrant (0.10.0)

v0.3.15 (2015-09-21)
-------------------
- [#156] Fixed uploading certs process for Chef-Server
- [#136] Fail fast if `environment` file is wrong
- Enabled Proxy Settings on Rake::generate_env
- Disabled Artifactory question on Rake:generate_env

v0.3.14 (2015-09-14)
-------------------
- Expose trusted_certs to the end-user
- Expose chefdk_version for build-nodes
- Bump delivery_build to 0.2.22
- Push-jobs fixed in delivery_build

v0.3.11 (2015-09-04)
-------------------
- Generate trusted_certs attributes to send to `delivery_build` cookbook
- Add `oc_id['vip']` to chef-server config
- [#155] Assemble Gem dependencies on a `cache` directory
- Break `delivery-sugar-extras` into its own repo
- Add FQDN option in the supermarket config

v0.3.8 (2015-07-31)
-------------------
- AWS Pipeline Stabilization (build-cookbook)

v0.3.7 (2015-07-31)
-------------------
- [#150] Fix SSH Driver for builder components

v0.3.6 (2015-07-23)
-------------------
- Fix the necessity of specifying builders spec
- Fix Artifactory functionality plus chefspecs

v0.3.5 (2015-07-21)
-------------------
- Releasing Major Library Refactoring v.0.3.5
- Modify Recipes to work with new Library Refactoring
- Substitute aws_driver for aws_data & vagrant_driver for vagrant_data
- Cleaning helpers.rb plus chefspecs
- Return the username of the Provisioning Driver Abstraction
- Create Chef specs for every single library
- Extract Builders Methods
- Extract Delivery Methods
- Extract Splunk Methods
- Extract Analytics Methods
- Extract Supermarket Methods
- Extract ChefServer Methods
- Extract Component Methods
- Helpers plus DSL Libraries
- Create DSL Library to split Helpers Methods
- Enable module_function on DeliveryCluster::Helper

v0.3.4 (2015-07-10)
-------------------
- Common Cluster Recipes
- Package repository management recipe

v0.3.3 (2015-07-07)
-------------------
- [#134] Customizable `delivery.rb`

v0.3.2 (2015-07-01)
-------------------
- [#140] Fix Supermarket Setup
- [#141] Fix Analytics Setup
- Add tests for Supermarket & Analytics recipes

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
