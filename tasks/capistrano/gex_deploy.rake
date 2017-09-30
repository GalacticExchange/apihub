namespace :deploy do

  desc 'copy configs'
  task :copy_configs do
    on roles(:app) do
      #execute "cd #{current_path} && bundle install --no-deployment "
      files = {
          "config/gex/gex_config.#{fetch(:gex_env)}.yml" => "config/gex/gex_config.yml"
      }
      files.each do |f, f_out|
        upload! f, "#{current_path}/#{f_out}"
      end
    end
  end

  desc 'init db'
  task :init_db do
    on roles(:app) do
      # Update options
      #within release_path do
        #with rails_env: fetch(:rails_env) do
          begin
            #raise 'not work'
            # upload dumps
            files = {
                "db-init/gex.sql.gz" => "gex.sql.gz",
                "db-init/gex_logs.sql.gz" => "gex_logs.sql.gz",
                #"db-init/gex.sql" => "gex.sql",
            }

            files.each do |f, f_out|
              #upload! f, "#{current_path}/#{f_out}"
              upload! f, "/tmp/#{f_out}"

              (execute :gunzip, "/tmp/#{f_out}") rescue nil
            end

            # secrets.yml
            f = File.join(File.dirname(__FILE__), "../../config/secrets.yml")
            config =YAML.load_file(f)[fetch(:rails_env)]


            db_host = config['db_host']
            db = config['db']
            db_user = config['db_user']
            db_pwd = config['db_password']


            mysql_p = "-h #{db_host} -u #{db_user} -p#{db_pwd}"
            cmd = "#{mysql_p} #{db} < /tmp/gex.sql"

            execute :mysql, cmd

            #
            db_logs_host = config['logs_db_host']
            db_logs = config['logs_db']
            db_logs_user = config['logs_db_user']
            db_logs_pwd = config['logs_db_password']

            mysql_p = "-h #{db_logs_host} -u #{db_logs_user} -p#{db_logs_pwd}"
            cmd = "#{mysql_p} #{db_logs} < /tmp/gex_logs.sql"

            execute :mysql, cmd

            execute 'rm /tmp/gex.sql'
            execute 'rm /tmp/gex_logs.sql'



            #
            #execute :rake, "install:init_db"
            #execute :rake, "install:init_db_logs"
          end
        end
      #end
    #end

  end

  desc 'init backup'
  task :init_backup do
    on roles(:app) do
      # Update options
      within release_path do
        with rails_env: fetch(:rails_env) do
          begin
            execute :rake, "optimacms_backups:install"
          end
        end
      end
    end
  end

  desc 'init options'
  task :init_options do
    on roles(:app) do
      # Update options
      within release_path do
        with rails_env: fetch(:rails_env) do
          begin
            execute :rake, "install:init"
          end
        end
      end
    end
  end

  desc 'update ansible scripts'
  task :update_ansible do
    on roles(:app) do
      #execute "cd /var/www/ansible && git reset --hard origin/master" rescue nil
      execute "cd /var/www/ansible && git pull  origin master"
    end
  end

  desc 'update chef'
  task :update_chef do
    on roles(:app) do
      execute "cd /var/www/chef && git pull origin master" rescue nil
    end
  end

  desc 'update tests'
  task :update_tests do
    on roles(:app) do
      execute "cd /var/www/tests && git pull origin master"
    end
  end



  desc 'clean cache options'
  task :clear_cache_options do
    #run_locally("RAILS_ENV=#{fetch(:rails_env)} rake cache:options:clear")

    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          begin
            execute :rake, "cache:options_clear"
          end
        end
      end
    end
  end



  desc 'copy images'
  task :copy_images do
    on roles(:app) do
      upload! "public/images/applications/", "#{current_path}/public/images/applications", :via=> :scp, :recursive => true
      #upload! 'public/images/applications', "#{current_path}/public/images/applications", :via=> :scp, :recursive => true
    end
  end

  desc 'copy data'
  task :copy_data do
    on roles(:app) do
      upload! "data", "#{current_path}", :via=> :scp, :recursive => true
    end
  end


  desc 'assets clean'
  task :assets_clean do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          begin
            #execute "cd #{current_path} && rm -rf public/assets/*"
            #execute "cd #{current_path} && rm -rf public/assets/.*.json" rescue nil

            execute "rm -rf public/assets/*"
            execute "rm -rf public/assets/.*.json" rescue nil
          end
        end
      end



      within current_path do
        with rails_env: fetch(:rails_env) do
          begin
          execute :rake, "tmp:clear"
          execute :rake, "tmp:cache:clear"
          execute :rake, "tmp:create"
          end
        end
      end


      within current_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "assets:clean"
        end
      end


    end
  end
end

