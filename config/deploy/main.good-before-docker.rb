set :gex_env, 'main'

#
set :repo_url, 'git@git.gex:gex/apihub.git'

# api.gex
server_ip = '51.1.1.21'
server_user = 'uadmin'
server_ssh_port = 22



#
role :app, [server_ip]
role :web, [server_ip]
role :db,  [server_ip]



#
set :application, 'apihub'
set :rails_env, 'main'
#set :branch, "master"
set :branch, "master"

server server_ip, user: server_user, roles: %w{web}, primary: true, port: server_ssh_port
set :deploy_to, "/var/www/apps/#{fetch(:application)}"


set :ssh_options, { forward_agent: true, user: server_user, password: 'PH_GEX_PASSWD1'}

