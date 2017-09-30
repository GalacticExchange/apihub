#
appname = 'apihub'
rails_env = 'main'

#
user = 'root'
group = 'root'

#
projects_root = "/var/www/apps"
app_root = "#{projects_root}/#{appname}/current"
name_prefix = "#{appname}-sidekiq-#{rails_env}"

# settings
stop_timeout = 1800

#
#rake_root = "/home/uadmin/.rvm/wrappers/ruby-2.3.3"
#bin_path   = "/home/uadmin/.rvm/gems/ruby-2.3.3/bin"

#rake_root = "/usr/local/rvm/wrappers/ruby-2.3.3"
bin_path   = "/usr/local/rvm/gems/ruby-2.3.3/bin"




#
num_workers = 1
configs = {'all_nolog'=>'sidekiq.all_nolog.yml', 'log' => 'sidekiq.log.yml'}
#configs = {'all_nolog'=>'sidekiq.all_nolog.yml'}

configs.each do |config_name, config_file|
  num_workers.times do |num|
    God.watch do |w|
      w.uid = user
      w.gid = group

      w.name          = "#{name_prefix}-#{config_name}-#{num}"
      w.group         = 'sidekiq'
      w.env           = { 'RAILS_ENV' => rails_env, 'QUEUE' => '*' }
      w.dir           = app_root

      w.pid_file = File.join(app_root, "tmp/pids/", "#{w.name}.pid")
      w.log           = File.join(app_root, 'log', "#{w.name}.log")

      #
      concurrency = 10 if config_name=='all_nolog'
      concurrency = 10 if config_name=='log'


      #
      sidekiq_options = "-e #{rails_env} -t #{stop_timeout}  -c #{concurrency} -C #{app_root}/config/#{config_file} -L #{w.log} -P #{w.pid_file}"
      # -d -c 1
      w.start = "cd #{app_root}; nohup #{bin_path}/bundle exec sidekiq -d  #{sidekiq_options} 2>&1 &"
      #w.stop  = "kill -TERM `cat #{w.pid_file}`"
      w.stop  = "cd #{app_root} && sidekiqctl stop #{w.pid_file} #{stop_timeout} "

      # v1
      #w.stop  = "kill -TERM `cat #{w.pid_file}`"

      # v3.
      # from http://richfisher.me/blog/2013/11/18/using-god-to-watch-unicorn-and-sidekiq/
      #w.start = "cd #{app_root}; nohup #{bin_path}/bundle exec sidekiq #{sidekiq_options} 2>&1 &"
      #w.stop  = "if [ -d #{app_root} ] && [ -f #{w.pid_file} ] && kill -0 `cat #{w.pid_file}`> /dev/null 2>&1; then cd #{app_root} && #{bin_path}/bundle exec sidekiqctl stop #{w.pid_file} #{stop_timeout} ; else echo 'Sidekiq is not running'; fi"


      #w.start = "bundle exec sidekiq -e #{rails_env} -c 1 -C #{app_root}/config/sidekiq.yml -L #{w.log}"
      #w.stop  = "if [ -d #{app_root} ] && [ -f #{w.pid_file} ] && kill -0 `cat #{w.pid_file}`> /dev/null 2>&1; then cd #{app_root} && #{bin_path}/bundle exec sidekiqctl stop #{w.pid_file} 10 ; else echo 'Sidekiq is not running'; fi"


      #
      #w.keepalive
      w.behavior(:clean_pid_file)

      #
      w.interval      = 30.seconds

      w.start_grace = 20.seconds
      w.restart_grace = 20.seconds

      #w.stop_signal = 'QUIT'
      w.stop_timeout = stop_timeout.seconds



      ### restart
      w.restart_if do |on|
        on.condition(:file_touched) do |c|
          c.interval = 5.seconds
          c.path = File.join(app_root, 'tmp', 'restart_sidekiq.txt')
        end

      end




# from godrb.com
      # determine the state on startup
      w.transition(:init, { true => :up, false => :start }) do |on|
        on.condition(:process_running) do |c|
          c.running = true
        end
      end

      # determine when process has finished starting
      w.transition([:start, :restart], :up) do |on|
        on.condition(:process_running) do |c|
          c.running = true
          c.interval = 5.seconds
        end

        # failsafe
        on.condition(:tries) do |c|
          c.times = 5
          c.transition = :start
          c.interval = 5.seconds
        end
      end

      # start if process is not running
      w.transition(:up, :start) do |on|
        on.condition(:process_running) do |c|
          c.running = false
        end
      end




=begin
      w.lifecycle do |on|
        on.condition(:flapping) do |c|
          c.to_state = [:start, :restart]
          c.times = 5
          c.within = 5.minute
          c.transition = :unmonitored
          c.retry_in = 10.minutes
          c.retry_times = 5
          c.retry_within = 2.hours
        end
      end
=end





    end
  end
end
