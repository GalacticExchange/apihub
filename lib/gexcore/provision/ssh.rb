module Gexcore::Provision

  class Ssh
    ### ssh
    def self.run_ssh_cmd(ssh_options, cmd, _interaction_handler=nil)

      #require 'net/ssh'

      output = ""
      res = 0

      begin

      if cmd.is_a? Array
        a_cmd = cmd
      else
        a_cmd = [cmd]
      end


      # debug
      #a_cmd = ['cd /mount/ansible/provisioner && bundle exec cap main provision:test_task']

      # fix rvm
      a_cmd.unshift('source /etc/profile.d/rvm.sh')

      #
      cmd = a_cmd.join '; '

      Gexcore::GexLogger.info('debug_provision', "script - start", {cmd: cmd, ssh: ssh_options})


      output = ''
      stderr_data = ''

      Net::SSH.start(ssh_options[:hostname], ssh_options[:user], :password => ssh_options[:pwd]) do |ssh|
        #output, stderr_data, exit_code, exit_signal = ssh.exec!("#{cmd}")
        #res_cmd = ssh.exec!("#{cmd}")
        output, stderr_data, exit_code, exit_signal = ssh_exec!(ssh, cmd)

        #Gexcore::GexLogger.info('debug_provision', "my - all res 1", {res: 0})
        #Gexcore::GexLogger.info('debug_provision', "my - all res", {output: output, stderr_data: stderr_data, exit_code: exit_code, exit_signal: exit_signal, stderr_data: stderr_data, exit_code: exit_code, exit_signal: exit_signal})

        if exit_code.to_i>0
          res = 0
        else
          res = 1
        end

      end

      Gexcore::GexLogger.debug('debug_provision', "ssh result", {res: res})


      res_output = ''

      begin
        res_output = output.force_encoding('utf-8')+"; "+stderr_data.force_encoding('utf-8')
      rescue => e
        res_output = 'OK. error in output'
        Gexcore::GexLogger.debug('debug_provision', "ssh script output error", {e: e})
      end

      res_res = {res: res, output: res_output}

      Gexcore::GexLogger.debug('debug_provision', "ssh script result with output", {res: res_res})

      return res_res

=begin
      require 'sshkit'

      pwd = ssh_options.delete(:pwd)

      # debug
      ssh_options[:hostname] = '51.0.0.55'

      host = SSHKit::Host.new(ssh_options)
      host.password = pwd

      output = ''

      # debug

      #cmd = 'cd /mount/ansible/provisioner && bundle exec cap -v'
      #cmd = 'pwd'
      #cmd = %Q(cd /mount/ansible/provisioner && _gex_env=main _cluster_id=362 _cluster_data='{"port_ssh":10337,"port_hadoop_resource_manager":10338,"port_hdfs":10339,"port_hdfs_namenode_webui":10340,"port_hue":10341,"port_spark_master_webui":10342,"port_spark_history":10343,"port_elastic":10344,"id":362,"uid":"3171247274090674","cluster_type":"onprem","name":"red-caelum","id_hex":"16a","hadoop_type":"cdh"}' bundle exec cap main provision:create_cluster)
      #cmd = %Q(cd /mount/ansible/provisioner && _gex_env=main _cluster_id=362 _cluster_data='{"port_ssh":10337,"port_hadoop_resource_manager":10338,"port_hdfs":10339,"port_hdfs_namenode_webui":10340,"port_hue":10341,"port_spark_master_webui":10342,"port_spark_history":10343,"port_elastic":10344,"id":362,"uid":"3171247274090674","cluster_type":"onprem","name":"red-caelum","id_hex":"16a","hadoop_type":"cdh"}' bundle exec cap main provision:test_task)
      #cmd = %Q(bash -c 'cd /mount/ansible/provisioner && bundle exec cap main provision:test_task' )
      #cmd = 'cd /mount/ansible/provisioner && bundle exec cap -v'
      cmd = %Q(source /etc/profile.d/rvm.sh; cd /mount/ansible/provisioner && bundle exec cap main provision:test_task)

      if cmd.is_a? Array
        a_cmd = cmd
      else
        a_cmd = [cmd]
      end

      # fix rvm


      #

      output = ""
      ih = _interaction_handler
      ih ||= interaction_handler_pwd(ssh_options[:user], pwd)

      Gexcore::GexLogger.info('debug_provision_script', "my - START", {cmd: cmd, ih: ih, ssh: ssh_options})
      Gexcore::GexLogger.info('debug_provision_script', "my - provision script", {cmd: cmd, ih: ih, ssh: ssh_options})

      SSHKit::Coordinator.new(host).each in: :sequence do
        #output = capture cmd
        a_cmd.each do |q|
          #output << capture(q)
          #execute(q, interaction_handler: SSHKit::MappingInteractionHandler.new({}, :info))
          execute(q, interaction_handler: ih)
        end
      end

      Gexcore::GexLogger.info('debug_provision_script', "provision script 0 ok ", {})

      #
      return {res: 1, output: output}
=end

    rescue => e
      Gexcore::GexLogger.debug('debug_provision', "provision - exception", {e: e})

      return {
          res: 0,
          output: "error: "+e.message,
      }
    end

    end


    def self.ssh_exec!(ssh, command)
      stdout_data = ""
      stderr_data = ""
      exit_code = nil
      exit_signal = nil
      ssh.open_channel do |channel|
        channel.exec(command) do |ch, success|
          unless success
            abort "FAILED: couldn't execute command (ssh.channel.exec)"
          end
          channel.on_data do |ch,data|
            stdout_data+=data
          end

          channel.on_extended_data do |ch,type,data|
            stderr_data+=data
          end

          channel.on_request("exit-status") do |ch,data|
            exit_code = data.read_long
          end

          channel.on_request("exit-signal") do |ch, data|
            exit_signal = data.read_long
          end
        end
      end
      ssh.loop
      [stdout_data, stderr_data, exit_code, exit_signal]
    end



    def self.interaction_handler_pwd(user, pwd, host='')
      {
          "#{user}@#{host}'s password:" => "#{pwd}\n",
          /#{user}@#{host}'s password: */ => "#{pwd}\n",
          "password: " => "#{pwd}\n",
          "password:" => "#{pwd}\n",
          "Password: " => "#{pwd}\n",
      }
    end



    def self.sshkit_run_locally(&block)
      require 'sshkit'
      require 'sshkit/dsl'

      SSHKit::Backend::Local.new(&block).run
    end

    def self.sshkit_on(hosts, options={}, &block)
      require 'sshkit'
      require 'sshkit/dsl'

      SSHKit::Coordinator.new(hosts).each(options, &block)
    end

  end
end
