name             'chef-server-12'
maintainer       'Chef Software Inc'
maintainer_email 'afiune@chef.io'
license          'Apache 2.0'
description      'Installs/Configures chef-server-12'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.17'

depends 'chef-ingredient'
depends 'hostsfile'

supports 'ubuntu'
supports 'centos'
supports 'redhat'
