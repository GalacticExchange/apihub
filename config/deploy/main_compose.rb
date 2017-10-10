require 'vault'
deploy_creds =  Vault.logical.read("secret/gex_api_deploy_creds").data[:dev]

set :log_level, :debug

set :gex_env, 'main'
set :rails_env, 'main'


#
set :repo_url, 'ssh://git@github.com:22/GalacticExchange/apihub.git'

server_ip = deploy_creds[:server_ip]
server_user = deploy_creds[:server_user]
server_pwd = deploy_creds[:server_pwd]
server_ssh_port = deploy_creds[:server_ssh_port]


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

