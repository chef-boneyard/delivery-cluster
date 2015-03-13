delivery-cluster cookbook
=========================

This cookbook setup a full delivery environment.

That includes:

*  1 -  Chef Server 12
*  1 -  Delivery Server
*  N -  Build Nodes
*  1 -  Analytics Server (Not Required)

It will install the appropriate platform-specific delivery package
and perform the initial configuration of Delivery Server.

Additionally you could Activate an Analytics Server. [Optional]

REQUIREMENTS
------------

### AWS Config
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

ATTRIBUTES
------------

### AWS

| Attribute                                           | Description                                 |
| --------------------------------------------------- | ------------------------------------------- |
| `['delivery-cluster']['aws']['key_name']`           | Key Pair to configure.                      |
| `['delivery-cluster']['aws']['ssh_username']`       | SSH username to use to connect to machines. |
| `['delivery-cluster']['aws']['image_id']`           | AWS AMI.                                    |
| `['delivery-cluster']['aws']['flavor']`             | Size/flavor of your machine.                |
| `['delivery-cluster']['aws']['security_group_ids']` | Security Group on AWS.                      |

### Chef Server Settings

| Attribute                                              | Description                       |
| ------------------------------------------------------ | --------------------------------- |
| `['delivery-cluster']['chef-server']['hostname']`      | Hostname of your Chef Server.     |
| `['delivery-cluster']['chef-server']['organization']`  | The organization name we will create for the Delivery Environment. |
| `['delivery-cluster']['chef-server']['flavor']`        | AWS Flavor of the Chef Server.   |

### Analytics Settings (Not required)

| Attribute                                              | Description                       |
| ------------------------------------------------------ | --------------------------------- |
| `['delivery-cluster']['analytics']['hostname']`      | Hostname of your Analytics Server.     |
| `['delivery-cluster']['analytics']['fqdn']`          | The Analytics FQDN to use for the `/etc/opscode-analytics/opscode-analytics.rb`. |
| `['delivery-cluster']['analytics']['flavor']`        | AWS Flavor of the Analytics Server.   |

### Delivery Server Settings

| Attribute                                         | Description                       |
| ------------------------------------------------- | --------------------------------- |
| `['delivery-cluster']['delivery']['version']`     | Delivery Version. See `attributes/default.rb` |
| `['delivery-cluster']['delivery']['pass-through']` | Allow the Artifact pass-through the delivery server. Set this parameter to `false` if your delivery server does not have VPN Access. With that, the artifact will be downloaded locally and uploaded to the server.|
| `['delivery-cluster']['delivery']['hostname']`    | Hostname of your Delivery Server. |
| `['delivery-cluster']['delivery']['enterprise']`  | A Delivery Enterprise that it will create. |
| `['delivery-cluster']['delivery']['fqdn']`        | The Delivery FQDN to substitute the IP Address. |
| `['delivery-cluster']['delivery']['flavor']`      | Flavor of the Chef Server. |

### Delivery Build Nodes Settings

| Attribute                                                 | Description                       |
| --------------------------------------------------------- | --------------------------------- |
| `['delivery-cluster']['builders']['hostname_prefix']`     | Hostname (prefix) of your Delivery Build Nodes. |
| `['delivery-cluster']['builders']['role']`                | Name of the Delivery Build Nodes Role. |
| `['delivery-cluster']['builders']['count']`               | Number of Build Nodes to create. |
| `['delivery-cluster']['builders']['additional_run_list']` | Additional run list items to apply to build nodes. |

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

#### Create a basic environment

```
$ cat environments/test.json
{
  "name": "test",
  "description": "",
  "json_class": "Chef::Environment",
  "chef_type": "environment",
  "override_attributes": {
    "delivery-cluster": {
      "id": "my_uniq_id",
      "aws": {
        "key_name": "delivery-test",
        "ssh_username": "ubuntu",
        "image_id": "ami-3d50120d",
        "subnet_id": "subnet-19ac017c",
        "security_group_ids": "sg-cbacf8ae",
        "use_private_ip_for_ssh": true
      },
      "delivery": {
        "flavor": "c3.xlarge",
        "enterprise": "my_enterprise",
        "version": "latest"
      },
      "chef-server": {
        "flavor": "c3.xlarge",
        "organization": "my_organization"
      },
      "analytics": {
        "flavor": "c3.xlarge"
      },
      "builders": {
        "flavor": "c3.large",
        "count": 3
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

LICENSE AND AUTHORS
===================
- Author: Salim Afiune (<afiune@chef.io>)
- Author: Seth Chisamore (<schisamo@chef.io>)
