chef-server-12 Cookbook
===============================

This cookbook install and maintain a Chef Server v12.

Additionally it can setup the initial configuration for Delivery.

Prerequisits
-----
This cookbook need an secret key to be able to handle the PEM key
in secure mode. If you are using Test Kitchen the key already exist.

If you want to regenerate the existing key run:
```
$ openssl rand -base64 512 > test/integration/default/encrypted_data_bag_secret
```
If you are using `chef-solo` you have to manually create the secret key and
configure `solo.rb`.

Platform
-----
Chef Server v12 packages are available for the following platforms:

* Redhat 6.5 64-bit
* Centos 6.5 64-bit
* Ubuntu 12.04, 12.10 64-bit

Usage Solo Mode
-----
This cookbook can be used on `solo` mode to spinup a Chef Server v12.

Steps:

- Transfer this cookbook to the node and ensure that it has chef installed. `/etc/chef/cookbooks/chef-server-12`
- Create a secret key. (Only if you need the Delivery Setup Process)

```
    # openssl rand -base64 512 > /etc/chef/encrypted_data_bag_secret
```
- Configure `/etc/chef/solo.rb`
```
cookbook_path "/etc/chef/cookbooks"
encrypted_data_bag_secret "/etc/chef/encrypted_data_bag_secret"
http_proxy ENV['http_proxy']
https_proxy ENV['https_proxy']
```
- Create a `/etc/chef/dna.json`
```
{
  "run_list" : ["chef-server-12::default"],

  /* This will override the default api_fqdn attribute from the cookbook */
  /* Use it only if you have multiple ip addresses or if you want to set */
  /* the hostname/FQDN on it. */

  "chef-server-12" : {
    "api_fqdn":"ANOTHER_IP_ADDRESS"
  }
}
```
- Run `chef-solo`
```
    # chef-solo --config /etc/chef/solo.rb --json-attributes /etc/chef/dna.json --log_level info
```

Usage Test-Kitchen Mode
-----
You basically need to run:

    kitchen converge [PLATFORM_YOU_WANT]

Contributing
------------
TODO: (optional) If this is a public cookbook, detail the process for contributing. If this is a private cookbook, remove this section.

e.g.
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------

* Author: Salim [Afiune](http://github.com/afiune/) <afiune@getchef.com>

Copyright 2014, Chef Software, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
