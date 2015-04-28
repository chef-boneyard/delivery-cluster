# `delivery-cluster`
This cookbook is licensed under apache 2.0 but the packages it installs are private soruce and require a license key. It will setup a full delivery environment.

That includes:

*  1 -  Chef Server 12
*  1 -  Delivery Server
*  N -  Build Nodes

Additionally it enables extra optional infrastructure:
*  1 -  Analytics Server (Not Required)
*  1 -  Splunk Server (Not Required)

It will install the appropriate platform-specific delivery package
and perform the initial configuration.

Make Help
------------
New `Rakefile` that will help you use Delivery Cluster! Give it a try:

```
salimafiune@afiuneChef:~/github/delivery-cluster
$ rake
Delivery Cluster Helper

Setup Tasks
The following tasks should be used to set up your cluster
rake setup:analytics      # Activate Analytics Server
rake setup:chef_server    # Setup a Chef Server
rake setup:cluster        # Setup the Chef Delivery Cluster that includes: [ Chef Server | Delivery Server | Build Nodes ]
rake setup:delivery       # Create a Delivery Server & Build Nodes
rake setup:prerequisites  # Install all the prerequisites on you system
rake setup:splunk         # Create a Splunk Server with Analytics Integration

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

Cluster Information
The following tasks should be used to get information about your cluster
rake info:delivery_creds      # Show Delivery admin credentials
rake info:list_core_services  # List all your core services

To switch your environment run:
  # export CHEF_ENV=my_new_environment
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

### Delivery Server Settings

| Attribute      | Description                       |
| ---------------| --------------------------------- |
| `version`      | Delivery Version. See `attributes/default.rb` |
| `pass-through` | Allow the Artifact pass-through the delivery server. Set this parameter to `false` if your delivery server does not have VPN Access. With that, the artifact will be downloaded locally and uploaded to the server.|
| `hostname`     | Hostname of your Delivery Server. |
| `enterprise`   | A Delivery Enterprise that it will create. |
| `fqdn`         | The Delivery FQDN to substitute the IP Address. |
| `flavor`       | Flavor of the Chef Server. |
| `license_file` | Absolute path to the `delivery.license` file on your provisioner node. To acquire this file, please speak with your CHEF account representative. |
| `{rhel or debian}`   | Optional Hash of delivery attrs: `{ "artifact": "http://my.delivery.pkg", "checksum": "123456789ABCDEF"}` |

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

Supported Platforms
-------------------

Delivery Server packages are available for the following platforms:

* EL (CentOS, RHEL) 6 64-bit
* Ubuntu 12.04, 14.04 64-bit

So please don't use another AMI type.

PROVISION
=========

#### Install your gem and cookbook dependencies

```
$ make prerequisites
```

#### Download your Delivery license key
Delivery requires a valid license to activate successfully. **If you do
not have a license key, you can request one from your CHEF account
representative.**

You will need to have the `delivery.license` file present on your provisioner
node. Specify the path to this file on your provisioner node in the
`node['delivery-cluster']['delivery']['license_file']` attribute.


#### Create an environment

This example includes every single functionality, please modify it as your needs require.
```
$ vi environments/test.json
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
        "bootstrap_proxy": "MY_PROXY_URL",
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
        "version": "latest",
        "license_file": "/home/user/delivery.license"
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

#### Provision your Delivery Cluster

```
$ rake setup:cluster
```

#### [OPTIONAL] Provision an Analytics Server

Once you have completed the `cluster` provisioning, you could setup an Analytics Server by running:

```
$ rake setup:analytics
```

That will provision and activate Analytics on your entire cluster.


#### [OPTIONAL] Provision a Splunk Server

Would you like to try our Splunk Server Integration with Analytics? If yes, provision the server by running:

```
$ rake setup:splunk
```


UPGRADE
========

```
$ rake maintenance:upgrade
```

SSH/Kitchen Local Provisioning
================
Included in this cookbook is a `.kitchen.ssh.yml` file that can build test nodes with test-kitchen for ssh provisioning.

`KITCHEN_YAML=.kitchen.ssh.yml kitchen list`

Use the vagrant `insecure_private_key` in your environment file for ssh.

```
      "ssh": {
        "ssh_username": "vagrant",
        "key_file": "~/.vagrant.d/insecure_private_key"
      }
```

Try using this `kitchen.json` environment:

```
$ vi environments/kitchen.json
{
  "name": "kitchen",
  "description": "Kitchen Test over SSH",
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "override_attributes": {
    "delivery-cluster": {
      "id": "kitchen",
      "driver": "ssh",
      "ssh": {
        "ssh_username": "vagrant",
        "key_file": "/Users/salimafiune/.vagrant.d/insecure_private_key"
      },
      "chef-server": {
        "fqdn":"33.33.33.10",
        "ip":"33.33.33.10",
        "organization": "kitchen"
      },
      "delivery": {
        "fqdn": "33.33.33.11",
        "ip": "33.33.33.11",
        "enterprise": "kitchen",
        "version": "latest",
        "license_file": "/home/user/delivery.license"
      },
      "builders": {
        "1": { "ip": "33.33.33.12" },
        "2": { "ip": "33.33.33.13" },
        "3": { "ip": "33.33.33.14" },
        "count": 3
      },
      "analytics": {
        "fqdn": "33.33.33.15",
        "ip": "33.33.33.15"
      },
      "splunk": {
        "fqdn": "33.33.33.16",
        "ip": "33.33.33.16",
        "username": "admin",
        "password": "salim"
      }
    }
  }
}
```

Create your instances:

```
KITCHEN_YAML=.kitchen.ssh.yml kitchen create
```

Setup your cluster:

```
$ rake setup:cluster
```

Watch out for your local machine resources! :smile:

LICENSE AND AUTHORS
===================
- Author: Salim Afiune (<afiune@chef.io>)
- Author: Seth Chisamore (<schisamo@chef.io>)
- Author: Tom Duffield (<tom@chef.io>)
- Author: Jon Morrow (<jmorrow@chef.io>)
