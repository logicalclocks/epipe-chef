
group node['hops']['group'] do
  gid node['hops']['group_id']
  action :create
  not_if "getent group #{node['hops']['group']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['epipe']['user'] do
  home "/home/#{node['epipe']['user']}"
  gid node['hops']['group']
  uid node['hops']['hdfs']['user_id']
  action :create
  shell "/bin/bash"
  manage_home true
  not_if "getent passwd #{node['epipe']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node['hops']['group'] do
  action :modify
  members ["#{node['epipe']['user']}"]
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node["kagent"]["certs_group"] do
  action :manage
  append true
  excluded_members node['epipe']['user']
  not_if { node['install']['external_users'].casecmp("true") == 0 }
  only_if { conda_helpers.is_upgrade }
end

include_recipe "java"

if node['platform_family'].eql?("rhel") && node['rhel']['epel'].downcase == "true"
  package "epel-release"
end

if node['platform_family'].eql?("rhel")
  package "openssl"
end

package_url = "#{node['epipe']['url']}"
base_package_filename = File.basename(package_url)
cached_package_filename = "#{Chef::Config['file_cache_path']}/#{base_package_filename}"

remote_file cached_package_filename do
  source package_url
  owner "root"
  mode "0644"
  action :create_if_missing
end


epipe_downloaded = "#{node['epipe']['home']}/.epipe.extracted_#{node['epipe']['version']}"
# Extract epipe
bash 'extract_epipe' do
        user "root"
        code <<-EOH
                if [ ! -d #{node['epipe']['dir']} ] ; then
                   mkdir -p #{node['epipe']['dir']}
                   chmod 755 #{node['epipe']['dir']}
                fi
                tar -xf #{cached_package_filename} -C #{node['epipe']['dir']}
                chown -R #{node['epipe']['user']}:#{node['hops']['group']} #{node['epipe']['home']}
                chmod 750 #{node['epipe']['home']}
                cd #{node['epipe']['home']}
                touch #{epipe_downloaded}
                chown #{node['epipe']['user']} #{epipe_downloaded}
        EOH
     not_if { ::File.exists?( epipe_downloaded ) }
end

file node['epipe']['base_dir'] do
  action :delete
  force_unlink true
end

link node['epipe']['base_dir'] do
  owner node['epipe']['user']
  group node['hops']['group']
  to node['epipe']['home']
end

directory node['data']['dir'] do
  owner 'root'
  group 'root'
  mode '0775'
  action :create
  not_if { ::File.directory?(node['data']['dir']) }
end

directory node['epipe']['data_volume']['root_dir'] do
  owner node['epipe']['user']
  group node['hops']['group']
  mode '0750'
end

directory node['epipe']['data_volume']['log_dir'] do
  owner node['epipe']['user']
  group node['hops']['group']
  mode '0750'
end

bash 'Move epipe logs to data volume' do
  user 'root'
  code <<-EOH
    set -e
    mv -f #{node['epipe']['log_dir']}/* #{node['epipe']['data_volume']['log_dir']}
    rm -rf #{node['epipe']['log_dir']}
  EOH
  only_if { conda_helpers.is_upgrade }
  only_if { File.directory?(node['epipe']['log_dir'])}
  not_if { File.symlink?(node['epipe']['log_dir'])}
end

link node['epipe']['log_dir'] do
  owner node['epipe']['user']
  group node['hops']['group']
  mode '0750'
  to node['epipe']['data_volume']['log_dir']
end
