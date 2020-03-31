maintainer       "Jim Dowling"
maintainer_email "jdowling@kth.se"
name             "epipe"
license          "Apache v2.0"
description      "Installs/Configures a HopsFS to ElasticSearch connector"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.3.0"
source_url       "https://github.com/hopshadoop/epipe-chef"

%w{ ubuntu debian centos }.each do |os|
  supports os
end

depends 'java', '~> 7.0.0'
depends 'ulimit2', '~> 0.2.0'
depends 'kagent'
depends 'hops'
depends 'ndb'
depends 'elastic'


recipe "epipe::install", "Installs Epipe Server"
recipe "epipe::default", "configures Epipe Server"
recipe "epipe::purge", "Deletes the Epipe Server"

attribute "epipe/default/private_ips",
          :description => "Set ip addresses",
          :type => "array"

attribute "epipe/user",
          :description => "User to run Epipe server as",
          :type => "string"

attribute "epipe/group",
          :description => "Group to run Epipe server as",
          :type => "string"

attribute "epipe/version",
          :description => "Version of epipe to use",
          :type => "string"

attribute "epipe/url",
          :description => "Url to epipe binaries",
          :type => "string"

attribute "epipe/dir",
          :description => "Parent directory to install epipe in (/srv is default)",
          :type => "string"

attribute "epipe/pid_file",
          :description => "Change the location for the pid_file.",
          :type => "string"

attribute "install/dir",
          :description => "Set to a base directory under which we will install.",
          :type => "string"

attribute "install/user",
          :description => "User to install the services as",
          :type => "string"

attribute "epipe/metrics_port",
          :description => "Port on which metrics are exposed",
          :type => "string"

