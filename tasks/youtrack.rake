require 'youtrack'
require './config/environment'

namespace :youtrack do

  task :force_update_all do
    res = Utrack::YoutrackService.update_all_users true
    puts "All (#{res}) users updated" if res
  end

  task :update_all do
    res = Utrack::YoutrackService.update_all_users false
    puts "#{res} new users loaded" if res
  end

  task :update_user, [:username] do |t,args|
    abort "No username passed. Try: rake youtrack:update_user ['username']" unless args[:username]
    res = Utrack::YoutrackService.update_by_username(args[:username])
    puts "User #{args[:username]} updated!" if res
  end

end
