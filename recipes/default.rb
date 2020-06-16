nmy_ip = my_private_ip()
my_public_ip = my_public_ip()

nn = private_recipe_ip("hops", "nn") + ":#{node['hops']['nn']['port']}"
elastic = all_elastic_ips_ports_str()


ndb_connectstring()

file "#{node['epipe']['base_dir']}/conf/config.ini" do
  action :delete
end

template"#{node['epipe']['base_dir']}/conf/config.ini" do
   source "config.ini.erb"
   owner node['epipe']['user']
   group node['hops']['group']
   mode 0750
   variables({:ndb_connectstring => node['ndb']['connectstring'],
                :database => "hops",
                :meta_database => "hopsworks",
                :hivemeta_database => "metastore",
                :elastic_addr => elastic,
            })
 end

 file "#{node['epipe']['base_dir']}/conf/config-reindex.ini" do
   action :delete
 end

 template"#{node['epipe']['base_dir']}/conf/config-reindex.ini" do
    source "config-reindex.ini.erb"
    owner node['epipe']['user']
    group node['hops']['group']
    mode 0750
    variables({:ndb_connectstring => node['ndb']['connectstring'],
                 :database => "hops",
                 :meta_database => "hopsworks",
                 :hivemeta_database => "metastore",
                 :elastic_addr => elastic,
             })
  end

template"#{node['epipe']['base_dir']}/bin/start-epipe.sh" do
  source "start-epipe.sh.erb"
  owner node['epipe']['user']
  group node['hops']['group']
  mode 0750
end

template"#{node['epipe']['base_dir']}/bin/reindex-epipe.sh" do
  source "reindex-epipe.sh.erb"
  owner node['epipe']['user']
  group node['hops']['group']
  mode 0750
end

template"#{node['epipe']['base_dir']}/bin/stop-epipe.sh" do
  source "stop-epipe.sh.erb"
  owner node['epipe']['user']
  group node['hops']['group']
  mode 0750
end

#when upgrading, we want to reindex the newly created projects index
bash 'reindex epipe' do
  user node['epipe']['user']
  timeout 7200
  code <<-EOF
     #{node['epipe']['base_dir']}/bin/reindex-epipe.sh
  EOF
  only_if { node['elastic']['projects']['reindex'] == "true" || node['elastic']['featurestore']['reindex'] == "true" }
end


case node['platform']
when "ubuntu"
 if node['platform_version'].to_f <= 14.04
   node.override['epipe']['systemd'] = "false"
 end
end


deps = ""
if exists_local("ndb", "mysqld")
  deps = "mysqld.service"
end
service_name="epipe"

if node['epipe']['systemd'] == "true"

  service service_name do
    provider Chef::Provider::Service::Systemd
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end

  case node['platform_family']
  when "rhel"
    systemd_script = "/usr/lib/systemd/system/#{service_name}.service"
  when "debian"
    systemd_script = "/lib/systemd/system/#{service_name}.service"
  end

  template systemd_script do
    source "#{service_name}.service.erb"
    owner "root"
    group "root"
    mode 0754
    variables({
              :deps => deps
              })
    action :create
if node['services']['enabled'] == "true"
    notifies :enable, resources(:service => service_name)
end
    notifies :restart, resources(:service => service_name)
  end

  kagent_config "#{service_name}" do
    action :systemd_reload
  end

else #sysv

  service service_name do
    provider Chef::Provider::Service::Init::Debian
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end

  template "/etc/init.d/#{service_name}" do
    source "#{service_name}.erb"
    owner node['epipe']['user']
    group node['hops']['group']
    mode 0754
if node['services']['enabled'] == "true"
    notifies :enable, resources(:service => service_name)
end
    notifies :restart, resources(:service => service_name), :immediately
  end

end

if node['kagent']['enabled'] == "true"
   kagent_config service_name do
     service "Hops"
     log_file "#{node['epipe']['base_dir']}/epipe.log"
   end
end

if service_discovery_enabled()
  # Register epipe with Consul
  consul_service "Registering ePipe with Consul" do
    service_definition "epipe-consul.hcl.erb"
    action :register
  end
end
