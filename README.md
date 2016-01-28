# `delivery-cluster`
This cookbook installs Chef Delivery, a solution for continuously delivering
applications and infrastructure safely at speed.

Delivery is not open source software and requires a license from Chef to install
and use. This cookbook is open source and released under the Apache 2.0 license,
but the packages it installs are private source and require a license key.

If you happened stumble here on your own you can request an [INVITE](https://www.chef.io/delivery/)
or speak with your account rep.

This cookbook will setup a full delivery cluster which includes:

*  1 -  Chef Server 12
*  1 -  Delivery Server
*  N -  Build Nodes (Recommend at least 3)
*  1 -  Supermarket Server (Required for cookbook workflow)

Additionally it enables extra optional infrastructure:
*  1 -  Analytics Server (Not Required)
*  1 -  Splunk Server (Not Required)

It will install the appropriate platform-specific delivery package
and perform the initial configuration.

Rake Help
------------
New `Rakefile` that will help you use Delivery Cluster! Give it a try:

```
salimafiune@afiuneChef:~/github/delivery-cluster
$ rake
Delivery Cluster Helper

Setup Tasks
The following tasks should be used to set up your cluster
rake setup:analytics             # Activate Analytics Server
rake setup:chef_server           # Setup a Chef Server
rake setup:cluster               # Setup the Chef Delivery Cluster that includes: [ Chef Server | Delivery Server | Build Nodes ]
rake setup:delivery              # Create a Delivery Server & Build Nodes
rake setup:delivery_build_nodes  # Create Delivery Build Nodes
rake setup:delivery_server       # Create a Delivery Server only
rake setup:generate_env          # Generate an Environment
rake setup:prerequisites[cache]  # Install all the prerequisites on you system
rake setup:splunk                # Create a Splunk Server with Analytics Integration
rake setup:supermarket           # Create a Supermarket Server

Maintenance Tasks
The following tasks should be used to maintain your cluster
rake maintenance:clean_cache  # Clean the cache
rake maintenance:update       # Update gem & cookbook dependencies
rake maintenance:upgrade      # Upgrade Delivery

Destroy Tasks
The following tasks should be used to destroy your cluster
rake destroy:all          # Destroy Everything
rake destroy:analytics    # Destroy Analytics Server
rake destroy:builders     # Destroy Build Nodes
rake destroy:chef_server  # Destroy Chef Server
rake destroy:delivery     # Destroy Delivery Server
rake destroy:splunk       # Destroy Splunk Server
rake destroy:supermarket  # Destroy Supermarket Server

Cluster Information
The following tasks should be used to get information about your cluster
rake info:delivery_creds      # Show Delivery admin credentials
rake info:list_core_services  # List all your core services

To switch your environment run:
  # export CHEF_ENV=my_environment_name
```

Easy Setup
------------

The easiest way to setup a Delivery Cluster is to follow these four steps:

#### 1) Download your Delivery license key
Delivery requires a valid license to activate successfully. **If you do
not have a license key, you can request one from your CHEF account
representative.**

You will need to have the `delivery.license` file present on your provisioner
node or local workstation and specify it on the next step.

#### 2) Install and Configure ChefDK

Follow the instructions at https://docs.chef.io/install_dk.html to install and configure chefdk as your default version of ruby.

#### 3) Create an environment

Generate an environment file using the following command

```
$ rake setup:generate_env
```

You can accept the default options by pressing `<enter>`. Note that you must customize the
configuration for Delivery's license file.

Remember to export your environment by running: `export CHEF_ENV=my_environment_name`

#### 4) Provision your Delivery Cluster

```
$ rake setup:cluster
```

#### Access to Delivery Cluster

At this time you should have your Delivery Cluster up & running.

Now it is time to get access. You can use the `admin` credentials shown by:

```
rake info:delivery_creds
```

#### Provision a Supermarket Server

A private Supermarket instance is required to resolve cookbook dependencies. Create one for your environment with the following command:

```
$ rake setup:supermarket
```

Additional features [OPTIONAL]
------------

#### Provision an Analytics Server

Once you have completed the `cluster` provisioning, you could setup an Analytics Server by running:

```
$ rake setup:analytics
```

That will provision and activate Analytics on your entire cluster.

#### Provision a Splunk Server

Would you like to try our Splunk Server Integration with Analytics? If yes, provision the server by running:

```
$ rake setup:splunk
```

Available Provisioning Methods
------------
This cookbook uses [chef-provisioning](https://github.com/chef/chef-provisioning) to manipulate the infrastructure acting as the orchestrator, it uses the default driver `vagrant` but you can switch drivers by modifying the attribute `['delivery-cluster']['driver']`

The available drivers that you can use are:

### Vagrant Driver [Default]
This driver will provision the Delivery cluster locally using [Vagrant](https://www.vagrantup.com/).
As such, you MUST have vagrant installed for this to function.

The `rake setup:generate_env` task will generate this for you.

If you edit this config by hand, you MUST provide:

1. `vm_memory` and `vm_cpus`.
2. `vm_box`.
3. `network` configuration.

Here is an example of the environment file using the vagrant driver.
```json
{
  "name": "test",
  "description": "Delivery Cluster Environment",
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "override_attributes": {
    "delivery-cluster": {
      "id": "test",
      "driver": "vagrant",
      "vagrant": {
        "ssh_username": "vagrant",
        "key_file": "/Users/username/.vagrant.d/insecure_private_key",
        "vm_box": "opscode-centos-6.6",
        "image_url": "https://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_centos-6.6_chef-provisionerless.box",
        "use_private_ip_for_ssh": true
      },
      "chef-server": {
        "organization": "test",
        "existing": false,
        "vm_hostname": "chef.example.com",
        "network": ":private_network, {ip: '33.33.33.10'}",
        "vm_memory": "2048",
        "vm_cpus": "2"
      },
      "delivery": {
        "version": "latest",
        "enterprise": "test",
        "artifactory": false,
        "license_file": "/Users/username/delivery.license",
        "vm_hostname": "delivery.example.com",
        "network": ":private_network, {ip: '33.33.33.11'}",
        "vm_memory": "2048",
        "vm_cpus": "2"
      },
      "supermarket": {
        "vm_hostname": "supermarket.example.com",
        "network": ":private_network, {ip: '33.33.33.13'}",
        "vm_memory": "2048",
        "vm_cpus": "2"
      },
      "builders": {
        "count": "1",
        "1": {
          "network": ":private_network, {ip: '33.33.33.14'}",
          "vm_memory": "2048",
          "vm_cpus": "2"
        },
        "delivery-cli": {
          "artifact": "https://delivery-packages.s3.amazonaws.com/cli/delivery-cli-20150408004719-1.x86_64.rpm",
          "checksum": "fa1f1724482182a9461c21a692b88ecc97e016b8307bd28834c2828eca702e6c"
        }
      }
    }
  }
}
```


### AWS Driver
This driver will provision the infrastructure in Amazon Ec2.

You MUST configure your `~/.aws/config` file like this:
```
$ vi ~/.aws/config
[default]
region = us-west-2
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_KEY
```
You also need to create a `security_group` with the following ports open

| Port           | Protocol    | Description                                 |
| -------------- |------------ | ------------------------------------------- |
| 10000 - 10003  | TCP | Push Jobs
| 8989           | TCP | Delivery Git (SCM)
| 443            | TCP | HTTP Secure
| 22             | TCP | SSH
| 80             | TCP | HTTP
| 5672           | TCP | Analytics MQ
| 10012 - 10013  | TCP | Analytics Messages/Notifier

The list of attributes that you have available are:

| Attribute                | Description                                 |
| ------------------------ | ------------------------------------------- |
| `key_name`               | Key Pair to configure.                      |
| `ssh_username`           | SSH username to use to connect to machines. |
| `chef_version`           | The chef version to install on the machine. |
| `chef_config`            | Anything you want dumped in `/etc/chef/client.rb` |
| `image_id`               | AWS AMI.                                    |
| `flavor`                 | Size/flavor of your machine.                |
| `aws_tags`               | Hash of aws tags to add to an specific component. |
| `security_group_ids`     | Security Group on AWS.                      |
| `bootstrap_proxy`        | Automatically configure HTTPS proxy. |
| `install_sh_path`        | Installation path of the shell script to install chef.|
| `use_private_ip_for_ssh` | Set to `true` if you want to use the private  ipaddress. |

Here is an example of how you specify them
```json
{
"name": "aws-example",
  "description": "",
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "override_attributes": {
    "delivery-cluster": {
      "id": "aws-example",
      "driver": "aws",
      "aws": {
        "key_name": "MY_PEM_KEY",
        "ssh_username": "ubuntu",
        "image_id": "ami-3d50120d",
        "subnet_id": "subnet-19ac017c",
        "security_group_ids": "sg-cbacf8ae",
        "bootstrap_proxy": "MY_PROXY_URL",
        "use_private_ip_for_ssh": true
      },
      "delivery": {
        "flavor": "c3.xlarge",
        "enterprise": "aws-example",
        "version": "latest",
        "license_file": "/home/user/delivery.license"
      },
      "chef-server": {
        "flavor": "c3.xlarge",
        "organization": "aws-example",
        "aws_tags": { "cool_tag": "awesomeness" }
      },
      "analytics": {
        "flavor": "c3.xlarge"
      },
      "supermarket": {
        "flavor": "c3.xlarge"
      },
      "splunk": {
        "flavor": "c3.xlarge",
        "password": "demo"
      },
      "builders": {
        "flavor": "c3.large",
        "count": 3
      }
    }
  }
}
```

### SSH Driver
This driver will NOT provision any infrastrucute. It assumes you have already provisioned the machines and it will manipulate then to install and configure the Delivery Cluster.

You have to provide:

1. Ip address or Hostname for all your machine resources.
2. Username
3. Either `key_file` or `password`

The list of attributes that you have available are:

| Attribute                | Description                                 |
| ------------------------ | ------------------------------------------- |
| `ssh_username`           | SSH username to use to connect to machines. |
| `chef_config`            | Anything you want dumped in `/etc/chef/client.rb` |
| `chef_version`           | The chef version to install on the machine. |
| `key_file`               | The SSH Key to use to connect to the machines.   |
| `password`               | The password to use to connect to the machines.  |
| `prefix`                 | Prefix to add at the bigining of any ssh-command.|
| `bootstrap_proxy`        | Automatically configure HTTPS proxy. |
| `install_sh_path`        | Installation path of the shell script to install chef.|
| `use_private_ip_for_ssh` | Set to `true` if you want to use the private  ipaddress. |

This is an example of how to specify this information
```json
{
"name": "ssh-example",
  "description": "",
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "override_attributes": {
    "delivery-cluster": {
      "id": "ssh-example",
      "driver": "ssh",
      "ssh": {
        "ssh_username": "ubuntu",
        "prefix": "echo myPassword | sudo -S ",
        "key_file": "~/.ssh/id_rsa.pem",
        "bootstrap_proxy": "MY_PROXY_URL",
        "chef_config": "http_proxy 'MY_PROXY_URL'\nno_proxy 'localhost'"
      },
      "chef-server": {
        "ip": "33.33.33.10",
        "organization": "ssh-example",
        "delivery_password": "SuperSecurePassword"
      },
      "delivery": {
        "ip": "33.33.33.11",
        "enterprise": "ssh-example",
        "version": "latest",
        "license_file": "/home/user/delivery.license"
      },
      "analytics": {
        "ip": "33.33.33.12"
      },
      "splunk": {
        "password": "demo",
        "ip": "33.33.33.13"
      },
      "supermarket": {
        "ip": "33.33.33.17"
      },
      "builders": {
        "count": 3,
        "1": { "ip": "33.33.33.14" },
        "2": { "ip": "33.33.33.15" },
        "3": { "ip": "33.33.33.16" }
      }
    }
  }
}

```

Global Attributes
------------

### common_cluster_recipes

Add any recipe that you need to add to the run_list of all the servers
of the delivery-cluster.

As an example:
* We would like to aply a security policy to every single server on the cluster.

  `security_policies::lock_root_login` locks down root login

This attribute would look like:

```
default['delivery-cluster']['common_cluster_recipes'] = ['security_policies::lock_root_login']
```

### trusted_certs

Add the list of trusted certificates you depend on. These certificates will get added
to the list of trusted_certs within `chefdk`.

Copy your custom certificates to the `.chef/trusted_certs` directory and then list them as follows:

```
default['delivery-cluster']['trusted_certs'] = {
  'Proxy Cert': 'my_proxy.cer',
  'Corp Cert': 'corporate.crt',
  'Open Cert': 'other_open.crt'
}
```

Passing raw attributes to Components
------------
Every single component in the cluster has the ability to pass raw attributes, this is very
useful for example to manipulate the behavior of the cookbooks that the mechines will have in
their run_list. Having said that, you will have available a special attribute per component
`node['delivery-cluster'][COMPONENT_NAME]['attributes']` that you can inject any raw attribute
that will be transfer directly to the machine.

Some examples;

* If we have to deny `runit` cookbook to configure a package cloud repo on the build-nodes
we have to pass the following attribute:

  ```ruby
  node['delivery-cluster']['builders']['attributes'] = { 'runit' => { 'prefer_local_yum' => true } }
  ```

* To add custom settings to the chef-server configuration (`chef-server.rb`) you can pass them as the following example:

  ```ruby
  node['delivery-cluster']['chef-server']['attributes'] = { 'chef-server-12' => { 'extra_config' => 'notification_email "info@example.com"' } }
  ```
* Finally, lets imagine you added a special cookbook called `corp-iptables` to create/configure iptables rules
inside the chef-server, then you want to manipulate it to add some extra rules from this cookbook, then you will
pass the attributes like this:

  ```ruby
  node['delivery-cluster']['chef-server']['attributes'] = { 'corp-iptables' => { 'rules' => 'LIST_OF_RULES' } }
 ```

Specific Attributes per Component
------------

There are aditional specific attributes per component that you can use to configure your cluster
in different ways.

### Chef Server Settings

| Attribute       | Description                       |
| --------------- | --------------------------------- |
| `hostname`      | Hostname of your Chef Server.     |
| `organization`  | The organization name we will create for the Delivery Environment. |
| `flavor`        | AWS Flavor of the Chef Server.   |
| `fqdn`          | The Chef Server FQDN to substitute the IP Address. |
| `existing`      | Set this to `true` if you want to use an existing chef-server. |
| `recipes`       | Additional recipes to run on your Chef Server. |
| `delivery_password` | Password of the Delivery User in the Chef Server. |

### Delivery Server Settings

| Attribute      | Description                       |
| ---------------| --------------------------------- |
| `version`      | Delivery Version. See `attributes/default.rb` |
| `pass-through` | Allow the Artifact pass-through the delivery server. Set this parameter to `false` if your delivery server does not have VPN Access. With that, the artifact will be downloaded locally and uploaded to the server.|
| `artifactory`  | Set to `true` if you want to use Chef Artifactory. (Requires Chef VPN)|
| `hostname`     | Hostname of your Delivery Server. |
| `enterprise`   | A Delivery Enterprise that it will create. |
| `ldap`         | LDAP config attributes. |
| `config`       | Specify custom configuration for the `delivery.rb`. |
| `fqdn`         | The Delivery FQDN to substitute the IP Address. |
| `flavor`       | Flavor of the Chef Server. |
| `license_file` | Absolute path to the `delivery.license` file on your provisioner node. To acquire this file, please speak with your CHEF account representative. |
| `{rhel or debian}`   | Optional Hash of delivery attrs: `{ "artifact": "http://my.delivery.pkg", "checksum": "123456789ABCDEF"}` |
| `recipes`      | Additional recipes to run on your Delivery Server. |

### Delivery Build Nodes Settings

| Attribute             | Description                       |
| --------------------  | --------------------------------- |
| `hostname_prefix`     | Hostname (prefix) of your Delivery Build Nodes. |
| `role`                | Name of the Delivery Build Nodes Role. |
| `count`               | Number of Build Nodes to create. |
| `additional_run_list` | Additional run list items to apply to build nodes. |
| `delivery-cli`        | Optional Hash of delivery-cli attrs: `{ "version": "0.3.0", "artifact": "http://my.delivery-cli.pkg", "checksum": "123456789ABCDEF"}` |

### Analytics Settings (Not required)

| Attribute       | Description                       |
| --------------- | --------------------------------- |
| `hostname`      | Hostname of your Analytics Server.|
| `fqdn`          | The Analytics FQDN to use for the `/etc/opscode-analytics/opscode-analytics.rb`. |
| `flavor`        | AWS Flavor of the Analytics Server.|
| `ip`            | [SSH Driver] Ip Address of the Analytics Server.|
| `host`          | [SSH Driver] Hostname of the Analytics Server.|

### Supermarket Settings (Not required)

| Attribute       | Description                       |
| --------------- | --------------------------------- |
| `hostname`      | Hostname of your Supermarket Server.|
| `fqdn`          | The Supermarket FQDN to use. Although Supermarket will consume it from `node['fqdn']` |
| `flavor`        | AWS Flavor of the Supermarket Server.|
| `ip`            | [SSH Driver] Ip Address of the Supermarket Server.|
| `host`          | [SSH Driver] Hostname of the Supermarket Server.|

Supported Platforms
-------------------

Delivery Server packages are available for the following platforms:

* EL (CentOS, RHEL) 6, 7 64-bit
* Ubuntu 12.04, 14.04 64-bit

So please don't use another AMI type.

UPGRADE
========

Follow the instructions of the following document: [UPGRADE.md](UPGRADE.md)

LICENSE AND AUTHORS
===================
- Author: Salim Afiune (<afiune@chef.io>)
- Author: Seth Chisamore (<schisamo@chef.io>)
- Author: Tom Duffield (<tom@chef.io>)
- Author: Jon Morrow (<jmorrow@chef.io>)

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
