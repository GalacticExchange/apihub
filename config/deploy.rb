# config valid only for current version of Capistrano
#lock '3.7.1'

# custom vars
set :gex_env, (ENV['GEX_ENV'] || fetch(:stage))
set :rails_env, (ENV['RAILS_ENV'] || fetch(:stage))

#
set :default_shell, '/bin/bash -l'

#
set :rvm_ruby_version, '2.3.3'
set :rvm_type, :user


#
#set :user, 'uadmin'
#set :group, 'dev'
set :deploy_user, 'uadmin'



#set :repo_url, 'git@git.gex:gex/apihub.git'
#set :repo_url, '.'

# set in :stage file
#set :application, 'appname'


# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 20


# Add necessary files and directories which can be changed on server.
my_config_dirs = %W{config config/environments}
#my_config_files = %W{.env.#{fetch(:rails_env)} config/database.yml config/secrets.yml config/environments/#{fetch(:rails_env)}.rb config/backup/#{fetch(:rails_env)}.yml }

#my_config_files = %W{ config/database.yml config/secrets.yml config/environments/#{fetch(:rails_env)}.rb config/backup/#{fetch(:rails_env)}.yml }
my_config_files = %W{ config/database.yml config/secrets.yml config/environments/#{fetch(:stage)}.rb config/gex/gex_config.#{fetch(:stage)}.yml config/backup/#{fetch(:stage)}.yml }
#my_config_files = %W{config/database.yml config/secrets.yml config/environments/#{fetch(:gex_env)}.rb }
my_app_dirs = %W{data public/system public/uploads public/img public/images}


# do not change below
set :linked_dirs, fetch(:linked_dirs, []).push('bin', 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle')
set :linked_dirs, fetch(:linked_dirs) + my_app_dirs
set :linked_files, fetch(:linked_files, []) + my_config_files

set :config_dirs,  my_config_dirs+my_app_dirs
set :config_files, my_config_files


=begin

# precompile assets - locations that we will look for changed assets to determine whether to precompile
set :assets_dependencies, %w(app/assets lib/assets vendor/assets Gemfile config/routes.rb)


namespace :deploy do
  namespace :assets do
    # precompile directly
    task :my_precompile do
      on roles(:app) do
        within "#{fetch(:deploy_to)}/current/" do
          #with RAILS_ENV: fetch(:environment) do
          with RAILS_ENV: fetch(:stage) do
            execute :rake, "assets:precompile"
          end
        end

        #execute "cd #{release_path} && rake assets:precompile RAILS_ENV=#{fetch(:stage)} "
        #execute "cd #{release_path} && RAILS_ENV=#{fetch(:stage)} bundle exec rake assets:precompile "

      end

      Rake::Task["deploy:restart"].invoke
    end

    desc "Precompile assets if changed"
    task :my_precompile_changed do
      on roles(:app) do
        invoke 'deploy:assets:precompile_changed'
        #Rake::Task["deploy:assets:precompile_changed"].invoke
      end
    end
  end
end

namespace :deploy do
  task :mycheck do
    on roles(:app) do
      warn 'PLATFORM='+RUBY_PLATFORM
      if RUBY_PLATFORM =~ /(win32)|(i386-mingw32)/
        warn '-------- winda'
      else
      end
    end
  end

end
=end


# whenever
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }






#after 'deploy:publishing', 'mydeploy:bundle'

before "deploy", "deploy:web:disable"
after "deploy", "deploy:web:enable"

#
#after 'deploy:published', 'gex_deploy:copy_configs'
#after 'deploy:published', 'gex_deploy:update_ansible'
#after 'deploy:published', 'gex_deploy:update_chef'
#after 'deploy:published', 'gex_deploy:update_tests'


after 'deploy', 'deploy:restart'
#after 'deploy', 'mydeploy:restart_god_apps'


# skip assets:precompile in the mode
if ENV['skip_assets']=='1'
  Rake::Task["deploy:assets:precompile"].clear_actions
else
  after 'deploy', 'deploy:clear_cache_options'
  before 'deploy:compile_assets', 'deploy:assets_clean'
end



# slack
set :slackistrano, {
    channel: '#maintenance',
    webhook: "https://hooks.slack.com/services/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"
}
