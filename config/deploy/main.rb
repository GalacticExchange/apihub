set :log_level, :debug

set :gex_env, 'main'
set :rails_env, 'main'


#
#set :repo_url, 'git@git.gex:gex/apihub.git'
set :repo_url, 'ssh://git@git.gex:5522/gex/apihub.git'

#server_ip = '10.1.12.21'
#server_user = 'root'
#server_pwd = 'PH_GEX_PASSWD1'
#server_ssh_port = 22

#server_ip = 'gex2.devgex.net'
#server_ip = '51.1.0.50'
server_ip = '51.0.0.21'
server_user = 'root'
server_pwd = 'PH_GEX_PASSWD1'
server_ssh_port = 22
#server_ssh_port = 8022



#
role :app, [server_ip]
role :web, [server_ip]
role :db,  [server_ip]


#
set :deploy_user, 'root'


# rvm
set :rvm_type, :system                     # Defaults to: :auto
#set :rvm_ruby_version, '2.0.0-p247'      # Defaults to: 'default'
#set :rvm_custom_path, '~/.myveryownrvm'  # only needed if not detected


#
set :application, 'apihub'
set :rails_env, 'main'
set :branch, "master"

server server_ip, user: server_user, roles: %w{web}, primary: true, port: server_ssh_port
set :deploy_to, "/var/www/apps/#{fetch(:application)}"


set :ssh_options, { forward_agent: true, user: server_user, password: server_pwd}

