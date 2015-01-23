delivery_cluster cookbook
===========

This cookbook setup a full delivery environment.

That includes:

* 1 Chef Server 12
* 1 Delivery Server
* N Build Nodes

It will install the appropriate platform-specific delivery package
and perform the initial configuration of Delivery Server.

REQUIREMENTS
============

AWS Config
----------
You MUST configure your `~/.aws/config` file like this:
```
$ vi ~/.aws/config
[default]
region = us-east-1
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_KEY
```

You also need to modify on the attribute section the following ones:
1) `['aws']['key_name']`            - Key Pair to configure.
2) `['aws']['ssh_username']`        - SSH username to use to connect to machines.
4) `['aws']['image_id']`            - AWS AMI.
5) `['aws']['flavor']`              - Size/flavor of your machine.
3) `['aws']['security_group_ids']`  - Security Group on AWS.
This need to have the following ports open:
* 10000 - 10003
* 8989
* 443
* 22
* 80

Chef Server Settings
----------
You can configure the chef-server with the following attributes:
1) `['delivery_cluster']['chef_server']['hostname']`     - Hostname of your Chef Server.
2) `['delivery_cluster']['chef_server']['organization']` - The organization name we will create for the Delivery Environment.
3) `['delivery_cluster']['chef_server']['flavor']`       - Flavor of the Chef Server.

Delivery Server Settings
----------
You can configure the delivery-server with the following attributes:
1) `['delivery_cluster']['delivery']['version']`    - Delivery Version. See `attributes/default.rb`
2) `['delivery_cluster']['delivery']['hostname']`   - Hostname of your Delivery Server.
3) `['delivery_cluster']['delivery']['enterprise']` - A Delivery Enterprise that it will create.
4) `['delivery_cluster']['delivery']['flavor']`     - Flavor of the Chef Server.

Delivery Build Nodes Settings
----------
2) `['delivery_cluster']['build_nodes']['hostname']` - Hostname (prefix) of your Delivery Build Nodes.
3) `['delivery_cluster']['build_nodes']['role']`     - Name of the Delivery Build Nodes Role.
3) `['delivery_cluster']['build_nodes']['N']`        - Number of Build Nodes to create. 

Supported Platforms
----------------

Delivery Server packages are available for the following platforms:

* Redhat 6.5 64-bit
* Centos 6.5 64-bit
* Ubuntu 12.04, 12.04 64-bit

So please don't use another AMI type.

LICENSE AND AUTHORS
===================
Author:: Salim Afiune (<afiune@chef.io>)
