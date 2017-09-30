namespace :upgrade do
  desc "udpate log"
  task :update_log_visible_client => :environment do
    ActiveRecord::Base.connection.execute("UPDATE log_system SET visible_client=(select visible_client FROm log_types where log_types.id = log_system.type_id) ")
  end

end
