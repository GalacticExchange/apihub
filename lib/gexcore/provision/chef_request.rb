module Gexcore::Provision
  class ChefRequest
    attr_accessor :base_dir, :host, :ssh_user, :node_name, :opts
    attr_accessor :cmd, :res_output, :exit_code, :exception

    def initialize(_base_dir, _host, _node_name, _opts)
      @base_dir = _base_dir
      @host = _host
      @opts = _opts
      @node_name = _node_name

    end

    def gex_logger
      Gexcore::BaseService.gex_logger
    end


    def build_cmd_opts
      # options
      h_opts = {}
      h_opts['ssh-user'] = opts[:ssh_user]
      h_opts['ssh-password'] = opts[:ssh_password]
      h_opts.reject!{|v| v.nil? || v.blank?}

      a_opts = []
      h_opts.each do |k, v|
        a_opts << "--#{k} #{v}"
      end
      s_opts = a_opts.join(" ")

      s_opts
    end

    def build_cmd_bootstrap
      s_opts = build_cmd_opts
      cmd_bootstrap = %Q(cd #{base_dir} && chef exec knife zero bootstrap #{host} --node-name #{node_name}  --overwrite #{s_opts} 2>&1)
    end

    def build_cmd_provision(filename_config, recipe)
      s_opts = build_cmd_opts
      cmd_provision = %Q(cd #{base_dir} && chef exec knife zero converge "name:#{node_name}" --json-attributes #{filename_config}   #{s_opts} --override-runlist #{recipe} #{s_opts} 2>&1)
    end

    def run(filename_config, recipe)
      cmd_bootstrap = build_cmd_bootstrap
      cmd_provision = build_cmd_provision(filename_config, recipe)

      # run command

      # with sshkit
=begin
      require 'sshkit'
      require 'sshkit/dsl'


      self.res_output = ""

      #local_ssh_user = 'uadmin'
      local_ssh_user = Gexcore::Settings.config.ruby_user

      srv = "#{local_ssh_user}@localhost"
      all_servers = [srv]

      gex_logger.debug "debug_provision_chef", "chef provision server", {srv: srv}


      a_output = []
      begin
        Gexcore::ProvisionService.sshkit_on all_servers do |s|
          #as(user: local_ssh_user) do
            #execute(cmd)
            a_output << capture(cmd_bootstrap)
            #a_output << capture(cmd_provision)
          #end
        end

      rescue => e
        self.exception = e
        self.exit_code = 1

        gex_logger.error "app_install_error", "Cannot provision master node", {exception: e.message}
        gex_logger.exception "chef provision error", e

        return false
      end
=end

      # with backticks
      self.res_output = ""

      local_ssh_user = Gexcore::Settings.config.ruby_user

      srv = "#{local_ssh_user}@localhost"

      gex_logger.debug "debug_provision_chef", "chef provision server", {srv: srv}


      a_output = []
      begin
        a_output << `ssh #{srv} '#{cmd_bootstrap}' `
        a_output << `ssh #{srv} '#{cmd_provision}' `

      rescue => e
        self.exception = e
        self.exit_code = 1

        gex_logger.error "app_install_error", "Cannot provision master node", {exception: e.message}
        gex_logger.exception "chef provision error", e

        return false
      end



      self.res_output = a_output.join("; ")
      gex_logger.debug "debug_provision_chef", "chef provision output", {cmd: [cmd_bootstrap, cmd_provision], output: self.res_output}


      self.exit_code=0

      return self.exit_code==0
    end


  end
end
