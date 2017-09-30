module Gexcore::Provision
  class Service < Gexcore::BaseService

    def gex_logger
      Gexcore::GexLogger
    end


    def self.run(task_name, cmd, sysdata={})
      gex_logger.debug "debug_provision", "provision script #{task_name} - start", {name: task_name, cmd: cmd}

      res = Response.new
      res.set_sysdata sysdata

      # run
      req = Gexcore::Provision::ProvisionerRequest.new
      res_query = req.run(cmd)

      #
      res.data[:output] = req.output

      #
      if !res_query
        # return error
        res.set_error('provision_error', 'Cannot provision', "Cannot run provision script #{task_name}")
        gex_logger.error('debug_provision', "provision #{task_name} - error", {cmd: cmd, output: req.output})
        return res
      end


      # res - ok
      gex_logger.info "debug_provision", "provision #{task_name} - ok", {cmd: cmd, output: req.output}

      res.set_data

      res
    end


    def self.build_cmd_cap(task_name, args)
      %Q(cd #{config.provisioner_dir} && _gex_env=#{Gexcore::Settings.provision_env} #{args} bundle exec cap #{Gexcore::Settings.provision_env} #{task_name})

    end

    def self.build_provisioner_cmd(task_name, args)
      %Q(cd #{config.provisioner_dir} && _gex_env=#{Gexcore::Settings.provision_env} #{args} bundle exec ruby #{task_name})
    end


    def self.build_cmd_ansible(playbook, args)
      playbook_filename = "#{config.provision_basedir}#{playbook}"
      is_dev = ['development'].include?(config.provision_env)

      extra_vars = ''
      if args.is_a? Hash
        args['_dev'] = 1 if is_dev
        extra_vars = args.to_json
      else
        s_dev = is_dev ? '_dev=1' : ''
        extra_vars = "#{s_dev} #{args}"
      end

      cmd = %Q{ansible-playbook -i #{config.ansible_inventory} #{playbook_filename} -e '#{extra_vars}' }

      cmd
    end


    def self.build_cmd_chef(base_dir, host, chef_node_name, opts, filename_config, recipe)
      req = Gexcore::Provision::ChefRequest.new(base_dir, host, chef_node_name, opts)

      cmd1 = req.build_cmd_bootstrap
      cmd2 = req.build_cmd_provision(filename_config, recipe)

      [cmd1, cmd2]
    end

    ###

    def self.params_hash_format(h, format="hash")
      if format=='hash'
        return h
      end

      res = ""

      if format=="kv"
        res = h.map{|k, v| "#{k}='#{v.is_a?(Hash) ? v.to_json : v.to_s}'"}.join(" ")
      end

      res
    end


    ### config

    def self.filename_properties_cluster(cluster)
      "#{Gexcore::Settings.dir_clusters_data}#{cluster.id}/cluster.json"
    end


    def self.filename_properties_app(container, app)
      File.join(Gexcore::Applications::Service.app_properties_base_dir(container, app), "app.json")
    end

    ### helpers

    def self.save_params_to_file(args, filename)
      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename,"w+") do |f|
        f.write(args.to_json)
      end

      true
    end

  end
end

