set :gex_env, 'production'
set :rails_env, 'production'

#
set :application, 'apihub'
set :rails_env, 'production'
set :repo_url, 'ssh://git@git.galacticexchange.io:5522/gex/apihub.git'

set :branch, "master"
#set :branch, "v_0_2_1"
#set :branch, "master" do
#"prod_20161031_final"
#"prod_20161102_1"
#end


server_ip = 'api.galacticexchange.io'
server_user = 'root'
server_pwd = 'PH_GEX_PASSWD1'
server_ssh_port = 22


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




server server_ip, user: server_user, roles: %w{web}, primary: true, port: server_ssh_port
set :deploy_to, "/var/www/apps/#{fetch(:application)}"


set :ssh_options, { forward_agent: true, user: server_user, password: server_pwd}
