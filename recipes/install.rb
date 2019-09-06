
group node['epipe']['group'] do
  action :create
  not_if "getent group #{node['epipe']['group']}"
end

user node['epipe']['user'] do
  home "/home/#{node['epipe']['user']}"
  gid node['epipe']['group']
  action :create
  shell "/bin/bash"
  manage_home true
  not_if "getent passwd #{node['epipe']['user']}"
end

group node['epipe']['group'] do
  action :modify
  members ["#{node['epipe']['user']}"]
  append true
end


include_recipe "java"

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
                chown -R #{node['epipe']['user']}:#{node['epipe']['group']} #{node['epipe']['home']}
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
  group node['epipe']['group']
  to node['epipe']['home']
end
