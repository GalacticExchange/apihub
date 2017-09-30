# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

#Rake.add_rakelib 'tasks'
#Dir.glob('tasks/*.rake').each { |r| load r}
Dir.glob('tasks/**/*.rake').each { |r| load r}


Rails.application.load_tasks

# fixes
Rake::Task['assets:precompile'].enhance ['bower:install']
