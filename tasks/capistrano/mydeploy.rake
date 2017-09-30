namespace :deploy do

  desc 'bundle install'
  task :bundle do
    on roles(:app) do
      #execute "cd #{current_path} && bundle install " rescue true
      execute "cd #{current_path} && bundle install --no-deployment "
    end
  end

  desc "Restart Application"
  task :restart do
    on roles(:app) do
      execute "touch #{current_path}/tmp/restart.txt"
      execute "touch #{current_path}/tmp/restart_sidekiq.txt"

    end
  end


  desc 'local bundle install'
  task :local_bundle_install do
    system("bundle install")
  end

  desc 'Git push'
  task :git_push do
    system("git add .")
    system("git commit -m \"automatic commit before deploy\"")
    system("git push origin master")

  end

  desc 'push gexcore'
  task :git_push_gexcore do
    system("cd ../gexcore; git add .; git commit -m \"mmx changes\"; git push origin master")

  end



end

