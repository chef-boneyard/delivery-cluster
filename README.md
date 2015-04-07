# `delivery-cluster`
This cookbook setup a full delivery environment.

That includes:

*  1 -  Chef Server 12
*  1 -  Delivery Server
*  N -  Build Nodes

Additionally it enables extra optional infrastructure:
*  1 -  Analytics Server (Not Required)
*  1 -  Splunk Server (Not Required)

It will install the appropriate platform-specific delivery package
and perform the initial configuration.

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
| `image_id`               | AWS AMI.                                    |
| `flavor`                 | Size/flavor of your machine.                |
| `security_group_ids`     | Security Group on AWS.                      |
| `use_private_ip_for_ssh` | Set to `true` if you want to use the private ipaddress. |

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
        "use_private_ip_for_ssh": true
      },
      "delivery": {
        "flavor": "c3.xlarge",
        "enterprise": "aws-example",
        "version": "latest"
      },
      "chef-server": {
        "flavor": "c3.xlarge",
        "organization": "aws-example"
      },
      "analytics": {
        "flavor": "c3.xlarge",
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

1. Ip address for all your machine resources
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
        "key_file": "~/.ssh/id_rsa.pem"
      },
      "chef-server": {
        "ip": "33.33.33.10",
        "organization": "ssh-example"
      },
      "delivery": {
        "ip": "33.33.33.11",
        "enterprise": "ssh-example",
        "version": "latest"
      },
      "analytics": {
        "ip": "33.33.33.12"
      },
      "splunk": {
        "password": "demo",
        "ip": "33.33.33.13"
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

### Delivery Server Settings

| Attribute      | Description                       |
| ---------------| --------------------------------- |
| `version`      | Delivery Version. See `attributes/default.rb` |
| `pass-through` | Allow the Artifact pass-through the delivery server. Set this parameter to `false` if your delivery server does not have VPN Access. With that, the artifact will be downloaded locally and uploaded to the server.|
| `hostname`     | Hostname of your Delivery Server. |
| `enterprise`   | A Delivery Enterprise that it will create. |
| `fqdn`         | The Delivery FQDN to substitute the IP Address. |
| `flavor`       | Flavor of the Chef Server. |

### Delivery Build Nodes Settings

| Attribute             | Description                       |
| --------------------  | --------------------------------- |
| `hostname_prefix`     | Hostname (prefix) of your Delivery Build Nodes. |
| `role`                | Name of the Delivery Build Nodes Role. |
| `count`               | Number of Build Nodes to create. |
| `additional_run_list` | Additional run list items to apply to build nodes. |

### Analytics Settings (Not required)

| Attribute       | Description                       |
| --------------- | --------------------------------- |
| `hostname`      | Hostname of your Analytics Server.|
| `fqdn`          | The Analytics FQDN to use for the `/etc/opscode-analytics/opscode-analytics.rb`. |
| `flavor`        | AWS Flavor of the Analytics Server.|

Supported Platforms
-------------------

Delivery Server packages are available for the following platforms:

* EL (CentOS, RHEL) 6 64-bit
* Ubuntu 12.04, 14.04 64-bit

So please don't use another AMI type.

PROVISION
=========

#### Install your deps

```
$ bundle install
```

#### Assemble your cookbooks

```
$ bundle exec berks vendor cookbooks
```

#### Create an environment 

This example includes every single functionality
```
$ cat environments/test.json
{
"name": "test",
  "description": "",
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "override_attributes": {
    "delivery-cluster": {
    "id": "MY_UNIQ_ID",
    "driver": "aws",
      "aws": {
        "key_name": "MY_PEM_KEY",
        "ssh_username": "ubuntu",
        "image_id": "ami-3d50120d",
        "subnet_id": "subnet-19ac017c",
        "security_group_ids": "sg-cbacf8ae",
        "use_private_ip_for_ssh": true
      },
      "ssh": {
        "ssh_username": "ubuntu",
        "key_file": "~/.ssh/id_rsa.pem"
      },
      "chef-server": {
        "flavor": "c3.xlarge",
        "ip": "33.33.33.10",
        "organization": "test"
      },
      "delivery": {
        "flavor": "c3.xlarge",
        "ip": "33.33.33.11",
        "enterprise": "test",
        "version": "latest"
      },
      "analytics": {
        "flavor": "c3.xlarge",
        "ip": "33.33.33.12"
      },
      "splunk": {
        "flavor": "c3.xlarge",
        "password": "demo",
        "ip": "33.33.33.13"
      },
      "builders": {
        "flavor": "c3.large",
        "count": 3,
        "1": { "ip": "33.33.33.14" },
        "2": { "ip": "33.33.33.15" },
        "3": { "ip": "33.33.33.16" }
      }
    }
  }
}
```

#### Run chef-client on the local system (provisioning node)

```
$ bundle exec chef-client -z -o delivery-cluster::setup -E test
```

Activate Analytics Server
========
In order to activate Analytics you MUST provision the entire `delivery-cluster::setup` first. After you are done completely you can execute a second `chef-zero` like:
```
$ bundle exec chef-client -z -o delivery-cluster::setup_analytics -E test
```

That will provision and activate Analytics on your entire cluster.

UPGRADE
========
In order to upgrade the existing infrastructure and cookbook dependencies you need to run the following steps:

#### Update your cookbook dependencies
```
$ bundle exec berks update
```
#### Assemble your cookbooks again

```
$ bundle exec berks vendor cookbooks
```

#### Run chef-client on the local system (provisioning node)

```
$ bundle exec chef-client -z -o delivery-cluster::setup -E test
```

SSH provisioning
================
Included in this cookbook is a `.kitchen.ssh.yml` file that can build test nodes for ssh provisioning.

`KITCHEN_YAML=.kitchen.ssh.yml kitchen list`

Use the vagrant `insecure_private_key` in your environment file for ssh.

```
      "ssh": {
        "ssh_username": "vagrant",
        "key_file": "~/.vagrant.d/insecure_private_key"
      }
```

LICENSE AND AUTHORS
===================
- Author: Salim Afiune (<afiune@chef.io>)
- Author: Seth Chisamore (<schisamo@chef.io>)
