require 'net/ssh'


module Gexcore::Provision
  class ProvisionerRequest
    attr_accessor :res, :cmd, :output, :exit_code, :exception

    def gex_logger
      Gexcore::GexLogger
    end

    def res_output
      output
    end

    def success?
      res[:res]==1
    end

    def error?
      !success?
    end

    def run(cmd)
      if !cmd.is_a? Array
        cmd = [cmd]
      end

      self.cmd= cmd.join ";"

      #
      srv_ip = Gexcore::Settings.provisioner_host
      ssh_user = Gexcore::Settings.provisioner_user
      ssh_pass = Gexcore::Settings.provisioner_pwd
      ssh_port = Gexcore::Settings.provisioner_port


      gex_logger.info('debug_provision', "provision script - before ssh", {cmd: cmd})

      res = Gexcore::Provision::Ssh.run_ssh_cmd(
          {user: ssh_user, hostname: srv_ip, port: ssh_port, pwd: ssh_pass},
          cmd,
          #Gexcore::Provision::Ssh.interaction_handler_pwd(ssh_user, ssh_pass, srv_ip)
      )

      self.output = res[:output]

      if res[:res]==0
        gex_logger.error('debug_provision', "provision ERROR", {cmd: cmd,output: self.res_output, exitcode: self.exit_code})
        return false
      end

      #if exit_code.to_i>0
      #
      #end

      gex_logger.info('debug_provision', "provision OK", {cmd: cmd,output: self.res_output, exitcode: self.exit_code})

      true
    end



    ### OLD


    def run_provisioner_2(cmd)
      self.cmd= cmd

      s_cmd = cmd
      s_cmd.gsub! /'/im, %q(\\\')
      s_cmd.gsub! /"/im, %q(\\\")

      #
      ssh_connect = %Q(-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p #{Gexcore::Settings.provisioner_port} root@#{Gexcore::Settings.provisioner_host})

      cmd_ssh  = %Q(ssh #{ssh_connect} -t "bash -lc '#{s_cmd}' 2>&1")

      gex_logger.info('ansible_cmd', "ansible ssh cmd", {cmd: cmd_ssh})

      #self.res_output = %x[#{cmd_ssh}]
      #self.exit_code = $?.exitstatus

      self.exit_code = 0

      cmd = cmd_ssh

      begin
        self.res_output = `#{cmd} 2>&1`
        self.exit_code = $?.exitstatus

        gex_logger.info('debug_ansible', "ansible output", {cmd: cmd,output: self.res_output, exitcode: self.exit_code})
      rescue => e
        gex_logger.info('debug_ansible', "ansible exception", {cmd: cmd, e: e.message})

        self.exit_code = 1
      end


      if exit_code.to_i>0
        gex_logger.info('debug_ansible', "ansible ERROR", {cmd: cmd,output: self.res_output, exitcode: self.exit_code})
        return false
      end

      gex_logger.info('debug_ansible', "ansible OK", {cmd: cmd,output: self.res_output, exitcode: self.exit_code})

      true
    end

    def run_local(cmd)
      #raise 'not supported'

      gex_logger.info('provision_cmd', "run cmd", {cmd: cmd})

      ##
      self.cmd= cmd

      begin
        #self.res_output = `#{cmd} 2>&1`
        #self.exit_code = $?.exitstatus

        #Bundler.with_clean_env do
        #sh "#{cmd} 2>&1"
        self.res_output = `#{cmd} 2>&1`
        self.exit_code = $?.exitstatus
        #end

        gex_logger.info('debug_provision', "provision output", {cmd: cmd,output: self.res_output, exitcode: self.exit_code})

          # cmd 2
          #s = 'ls -la'
          #s_res = `#{s} 2>&1`
          #gex_logger.info('debug_ansible', "ansible debug", {cmd: s,output: s_res})

      rescue => e
        gex_logger.info('debug_provision', "provision exception", {cmd: cmd, e: e.message})

        self.exit_code = 1
      end


      if exit_code.to_i>0
        gex_logger.info('debug_provision', "provision ERROR", {cmd: cmd,output: self.res_output, exitcode: self.exit_code})
        return false
      end

      gex_logger.info('debug_provision', "provision OK", {cmd: cmd,output: self.res_output, exitcode: self.exit_code})


      #res_cmd= nil
      # stdout and stderr, exit code and exit signal
      #res_ssh = Net::SSH.start(cfg.ansible_host, cfg.ansible_user, :password => cfg.ansible_pwd) do |ssh|
      #res_cmd = output = ssh.exec!(cmd)
      #  res_output = output
      #end

      true
    end



  end
end

