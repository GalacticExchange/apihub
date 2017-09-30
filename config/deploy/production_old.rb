
set :gex_env, 'production'

server_ip = '46.172.71.53'

#
role :app, [server_ip]
role :web, [server_ip]
role :db,  [server_ip]



#
set :application, 'apihub'
set :rails_env, 'production'
#set :repo_url, 'ssh://git@46.172.71.50:5522/gex/apiruby.git'
set :repo_url, 'ssh://git@git.galacticexchange.io:5522/gex/apihub.git'
#set :branch, "v_0_2_1"

server "#{server_ip}:5024", user: 'uadmin', roles: %w{web}, primary: true
set :deploy_to, "/var/www/apps/#{fetch(:application)}"

set :ssh_options, { forward_agent: true, user: 'uadmin', }


