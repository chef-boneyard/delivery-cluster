delivery-cluster cookbook
=========================

This cookbook setup a full delivery environment.

That includes:

* 1 Chef Server 12
* 1 Delivery Server
* N Build Nodes

It will install the appropriate platform-specific delivery package
and perform the initial configuration of Delivery Server.

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

You also need to modify on the attribute section the following ones:
1) `['delivery-cluster']['aws']['key_name']`            - Key Pair to configure.
2) `['delivery-cluster']['aws']['ssh_username']`        - SSH username to use to connect to machines.
4) `['delivery-cluster']['aws']['image_id']`            - AWS AMI.
5) `['delivery-cluster']['aws']['flavor']`              - Size/flavor of your machine.
3) `['delivery-cluster']['aws']['security_group_ids']`  - Security Group on AWS.
This need to have the following ports open:
* 10000 - 10003
* 8989
* 443
* 22
* 80

### Chef Server Settings
You can configure the chef-server with the following attributes:
1) `['delivery-cluster']['chef-server']['hostname']`     - Hostname of your Chef Server.
2) `['delivery-cluster']['chef-server']['organization']` - The organization name we will create for the Delivery Environment.
3) `['delivery-cluster']['chef-server']['flavor']`       - Flavor of the Chef Server.

### Delivery Server Settings
You can configure the delivery-server with the following attributes:
1) `['delivery-cluster']['delivery']['version']`    - Delivery Version. See `attributes/default.rb`
2) `['delivery-cluster']['delivery']['hostname']`   - Hostname of your Delivery Server.
3) `['delivery-cluster']['delivery']['enterprise']` - A Delivery Enterprise that it will create.
4) `['delivery-cluster']['delivery']['flavor']`     - Flavor of the Chef Server.

### Delivery Build Nodes Settings
1) `['delivery-cluster']['builders']['hostname_prefix']` - Hostname (prefix) of your Delivery Build Nodes.
2) `['delivery-cluster']['builders']['role']`            - Name of the Delivery Build Nodes Role.
3) `['delivery-cluster']['builders']['N']`               - Number of Build Nodes to create.

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
      "aws": {
        "key_name": "delivery-test",
        "ssh_username": "ubuntu",
        "image_id": "ami-3d50120d",
        "security_group_ids": "sg-cbacf8ae",
        "use_private_ip_for_ssh": true
      },
      "delivery": {
        "flavor":"c3.xlarge"
      },
      "chef-server": {
        "flavor":"c3.xlarge"
      },
      "builders": {
        "flavor": "c3.large"
      }
    }
  }
}
```

#### Run chef-client on the local system (provisioning node)

```
$ bundle exec chef-client -z -o delivery-cluster::setup -E test
```

LICENSE AND AUTHORS
===================
- Author: Salim Afiune (<afiune@chef.io>)
- Author: Seth Chisamore (<schisamo@chef.io>)
