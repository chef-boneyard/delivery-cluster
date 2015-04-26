name             'chef-server-12'
maintainer       'Chef Software Inc'
maintainer_email 'afiune@chef.oi'
license          'All rights reserved'
description      'Installs/Configures chef-server-12'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.4'

depends 'chef-server-ingredient'

supports 'ubuntu'
supports 'centos'
supports 'redhat'
