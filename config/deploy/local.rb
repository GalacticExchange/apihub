#set :gex_env, 'main'
#set :rails_env, 'main'

#
set :repo_url, 'git@git.gex:gex/apihub.git'
#set :repo_url, 'file:///var/www/temp/apihub/'

server_ip = 'localhost'
#server_ssh_port = 22

#
role :app, [server_ip]
role :web, [server_ip]
role :db,  [server_ip]


# rvm
set :rvm_type, :system                     # Defaults to: :auto
#set :rvm_ruby_version, '2.0.0-p247'      # Defaults to: 'default'
#set :rvm_custom_path, '~/.myveryownrvm'  # only needed if not detected

#
set :application, 'apihub'
set :branch, "master"

#server server_ip, user: 'root', roles: %w{web}, primary: true, port: server_ssh_port
server 'localhost', roles: %w{web app}, primary: true

set :deploy_to, "/var/www/apps/#{fetch(:application)}"


set :ssh_options, { forward_agent: true, user: 'root', }


