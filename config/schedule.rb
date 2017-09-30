# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

#
app_env = ENV['app_env'] || ENV['RAILS_ENV']

root = File.absolute_path(File.dirname(__FILE__))
app_dir = File.expand_path("../../", __FILE__)+'/'

# NOT USED
# see gex-servers/backups - all backups scheduler are manager there
#####


=begin
every 4.hours do
  command "app_env=#{app_env} backup perform -t db_backup --root-path #{app_dir}backup"
end

every 4.hours do
  command "app_env=#{app_env} backup perform -t app_files_backup --root-path #{app_dir}backup"
end

every 1.day, :at => '5:30 am' do
  command "app_env=#{app_env} backup perform -t user_files_backup --root-path #{app_dir}backup"
end

=end



#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
