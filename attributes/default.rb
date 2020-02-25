include_attribute "kagent"
include_attribute "hops"
include_attribute "ndb"
include_attribute "elastic"
include_attribute "elasticsearch"

default['epipe']['version']                  = "0.12.0"
default['epipe']['user']                     = node['install']['user'].empty? ? node['hops']['hdfs']['user'] : node['install']['user']
default['epipe']['url']                      = "#{node['download_url']}/epipe/#{node['platform_family']}/epipe-#{node['epipe']['version']}.tar.gz"
default['epipe']['systemd']                  = "true"
default['epipe']['dir']                      = node['install']['dir'].empty? ? "/srv" : node['install']['dir']
default['epipe']['home']                     = node['epipe']['dir'] + "/epipe-" + "#{node['epipe']['version']}"
default['epipe']['base_dir']                 = "#{node['epipe']['dir']}/epipe"
default['epipe']['pid_file']                 = "/tmp/epipe.pid"
default['epipe']['log_dir']                  = "#{node['epipe']['base_dir']}/logs"
default['epipe']['log_rotation_size']        = "67108864"
default['epipe']['log_max_files']            = "10"

default['epipe']['metrics_port']             = "29191"
