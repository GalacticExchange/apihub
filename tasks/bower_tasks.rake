namespace :bower do
  task :install do
    system('bower install')
  end

  #Rake::Task['assets:precompile'].enhance ['bower:install']

end

