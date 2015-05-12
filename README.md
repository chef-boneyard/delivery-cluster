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
*  N -  Build Nodes

Additionally it enables extra optional infrastructure:
*  1 -  Supermarket Server (Not Required)
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
rake setup:generate_env[name]    # Generate an Environment
rake setup:prerequisites         # Install all the prerequisites on you system
rake setup:splunk                # Create a Splunk Server with Analytics Integration
rake setup:supermarket           # Create a Supermarket Server

Maintenance Tasks
The following tasks should be used to maintain your cluster
rake maintenance:clean_cache  # Clean the cache
rake maintenance:upgrade      # Upgrade your infrastructure

Destroy Tasks
The following tasks should be used to destroy you cluster
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
  # export CHEF_ENV=my_new_environment
```

Easy Setup
------------

The easiest way to setup a Delivery Cluster is to follow these four steps:

#### 1) Download your Delivery license key
Delivery requires a valid license to activate successfully. **If you do
not have a license key, you can request one from your CHEF account
representative.**

You will need to have the `delivery.license` file present on your provisioner
node or local workstation.

#### 2) Provisioning infrastructure [SSH/Kitchen]

You can provision your infrastructure on your prefered provider. We will use
[KichenCI](http://kitchen.ci/) for the easy setup so you can get familiarize.

Depending on the resources you have on your workstation we recommend you to
create the minimum number of instances (3):

```
$ export KITCHEN_YAML=.kitchen.ssh.yml
$ kitchen create chef-server
$ kitchen create delivery-server
$ kitchen create build-node1
```

#### 3) Create an environment

Use the `rake` task `generate_env[name]` (substitute `name` with your environment name)
to generate an environment file.

**Use the defaults by pressing <enter> on all of the questions.**

```
$ rake setup:generate_env[name]
```

Do not forget to `export` your new environment.

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

#### Provision a Supermarket Server

If you have cookbook dependencies to resolve, try our Supermarket Server by running:

```
$ rake setup:supermarket
```

Available Provisioning Methods
------------
This cookbook uses [chef-provisioning](https://github.com/chef/chef-provisioning) to manipulate the infrastructure acting as the orchestrator, it uses the default driver `aws` but you can switch drivers by modifying the attribute `['delivery-cluster']['driver']`

The available drivers that you can use are:

### AWS Driver [Default]
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

The list of attributes that you need to specify are:

| Attribute                | Description                                 |
| ------------------------ | ------------------------------------------- |
| `key_name`               | Key Pair to configure.                      |
| `ssh_username`           | SSH username to use to connect to machines. |
| `chef_config`            | Anything you want dumped in `/etc/chef/client.rb` |
| `image_id`               | AWS AMI.                                    |
| `flavor`                 | Size/flavor of your machine.                |
| `security_group_ids`     | Security Group on AWS.                      |
| `bootstrap_proxy`        | Automatically configure HTTPS proxy. |
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
        "organization": "aws-example"
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
        "organization": "ssh-example"
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

Specific Attributes per Machine
------------

### Chef Server Settings

| Attribute       | Description                       |
| --------------- | --------------------------------- |
| `hostname`      | Hostname of your Chef Server.     |
| `organization`  | The organization name we will create for the Delivery Environment. |
| `flavor`        | AWS Flavor of the Chef Server.   |
| `fqdn`          | The Chef Server FQDN to substitute the IP Address. |
| `existing`      | Set this to `true` if you want to use an existing chef-server. |
| `recipes`       | Additional recipes to run on your Chef Server. |

### Delivery Server Settings

| Attribute      | Description                       |
| ---------------| --------------------------------- |
| `version`      | Delivery Version. See `attributes/default.rb` |
| `pass-through` | Allow the Artifact pass-through the delivery server. Set this parameter to `false` if your delivery server does not have VPN Access. With that, the artifact will be downloaded locally and uploaded to the server.|
| `artifactory`  | Set to `true` if you want to use Chef Artifactory. (Requires Chef VPN)|
| `hostname`     | Hostname of your Delivery Server. |
| `enterprise`   | A Delivery Enterprise that it will create. |
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

* EL (CentOS, RHEL) 6 64-bit
* Ubuntu 12.04, 14.04 64-bit

So please don't use another AMI type.

UPGRADE
========

```
$ rake maintenance:upgrade
```

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
