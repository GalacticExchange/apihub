module Gexcore::Applications
  class Provision < Gexcore::BaseService


    ### install app

    def self.app_provision_master(application_id, sysdata={}, callback_after=nil)
      gex_logger.debug('debug_provision', 'app_provision_master - start', {application_id: application_id})

      #
      res = Response.new
      res.set_sysdata sysdata

      #
      app = ClusterApplication.find(application_id)
      cluster = app.cluster
      res.sysdata[:application_id] = application_id
      res.sysdata[:cluster_id] = cluster.id

      gex_logger.info('application_install', "app provision - before script. app_name: #{app.name}", {application_id: application_id, cluster_id: cluster.id})

      # run provision script - from app
      res_app_script = app_provision_master_app_script(application_id, sysdata)

      gex_logger.debug('debug_provision', 'after res_app_script', {})

      if res_app_script.error?
        #
        app.set_install_error!

        gex_logger.error('debug_provision', 'after res_app_script - error', {application_id: application_id, cluster_id: cluster.id})
        return res_app_script
      end

      # run common provision script
      res_gex_script = app_provision_master_gex_script(application_id, sysdata)
      if res_gex_script.error?
        #
        app.set_install_error!

        #
        gex_logger.error('debug_provision', 'error app_provision_master_gex_script', {application_id: application_id, cluster_id: cluster.id})
        return res_gex_script
      end


      # callbacks
      if callback_after
        gex_logger.debug('debug_provision', 'provision Running callback ', {fn: callback_after})

        #callback_after.call(application_id)
        begin
          res_callback = Gexcore::Applications::Service.send(callback_after.to_sym, application_id)

          if res_callback.error?
            gex_logger.error "application provision error", "Callback error"

            res.set_error('application_install_error', 'Cannot provision application', 'Cannot call after script')
            return res
          end
        rescue => e
          gex_logger.exception "application provision error", e

          res.set_error('application_install_error', 'Cannot provision application', 'Cannot call after script')
          return res
        end

      end

      #gex_logger.critical('debug_provision', 'after callback')
      gex_logger.info('application_install', "app provision - after all. app_name: #{app.name}", {application_id: application_id, cluster_id: cluster.id})

      res.set_data

      res
    end


    def self.app_provision_master_app_script(application_id, sysdata={})
      gex_logger.debug("debug_provision", "provision master start", {application_id: application_id})

      #
      res = Response.new
      res.set_sysdata sysdata

      #
      app = ClusterApplication.find(application_id)
      cluster = app.cluster
      res.sysdata[:application_id] = application_id
      res.sysdata[:cluster_id] = cluster.id


      #
      app_basename = app.name
      app_basename = app.library_application.name rescue nil

      # run provision
      script = Gexcore::Provision::Service.build_cmd_cap(
          'provision:app_install_master',
          "_cluster_id=#{app.cluster_id} _app_id=#{app.id} "
      )
      res_provision = Gexcore::Provision::Service.run('app_install_master', script)


      # OLD - 2017-05-16
=begin
      # run chef recipe on master
      container_hadoop_master = cluster.get_master_container('hadoop')
      hadoop_master_ipv4 = container_hadoop_master.public_ip

      filename_config = Gexcore::Applications::Service.config_for_application_filename(app)

      recipe = "#{app_basename}::master"
      chef_node_name = "master-#{cluster.id}"
      from_dir = File.join(config.chef_dir, 'config-knife/master_node')

      opts = {
          ssh_user: 'root',
          #ssh_password: '4658204248',
          ssh_password: 'vagrant',
      }

      # check if recipe exists
      recipe_exist = true
      filename_recipe = File.join(config.chef_dir, "cookbooks-apps/#{app_basename}/recipes", "master.rb")
      gex_logger.debug('debug_provision', 'check recipe', {f: filename_recipe})

      if !File.exist?(filename_recipe)
        recipe_exist = false
      end

      if !recipe_exist
        # nothing to do
        gex_logger.debug('debug_provision', 'no recipe for provision master for this app', {application_id: app.id})

        # res - ok
        return res.set_data
      end

      #cmd = Gexcore::Provision::Service.build_cmd_chef(from_dir, hadoop_master_ipv4, chef_node_name, opts, filename_config, recipe)
      #res_provision = Gexcore::Provision::Service.run("app_install_master_app", cmd)
=end

      if res_provision.error?
        # rollback
        #res_provision_clean = Gexcore::Provision::run_script_ansible("rollback_create_cluster.yml", script_params)

        # return error
        res.set_error('application_install_error', 'Cannot provision application', 'Cannot run provision script')

        gex_logger.error('debug_provision', 'Cannot provision application')

        return res
      end

      gex_logger.debug('debug_provision', 'provision master ok')


      # res - ok
      res.set_data

      res
    end

    # run provision script add_app
    def self.app_provision_master_gex_script(application_id, sysdata={})
      gex_logger.debug("debug_provision", "provision master start install - add_app")

      # res
      res = Response.new
      res.set_sysdata sysdata


      # input
      if application_id.is_a?(Integer)
        app = ClusterApplication.get_by_id(application_id)
      else
        app = application_id
      end

      #container = app.containers[0]

      # run provision script
      app_data = build_params_app_data(app, 'hash')

      # save data to consul
      #Gexcore::Consul::Service::update_app_data(app, app_data)

      script = Gexcore::Provision::Service.build_cmd_cap(
          'provision:add_app',
          #"_cluster_id=#{app.cluster_id} _app_id=#{app.id} _app_data='#{app_data.to_json}'"
          "_cluster_id=#{app.cluster_id} _app_id=#{app.id} "
      )
      res_provision = Gexcore::Provision::Service.run('add_app', script)

      if res_provision.error?
        return res.set_error('app_install_error', 'Cannot install app', 'Cannot run provision script add_app')
      end

      res.set_data
      res
    end




    ## uninstall

    def self.app_uninstall_provision_master(application_id, sysdata={}, callback_after=nil)
      #
      res = Response.new
      res.set_sysdata sysdata

      #
      app = ClusterApplication.find(application_id)
      cluster = app.cluster
      res.sysdata[:application_id] = application_id
      res.sysdata[:cluster_id] = cluster.id


      # run provision script - from app
=begin
      res_app_script = app_uninstall_provision_master_app_script(application_id, sysdata)

      if res_app_script.error?
        #
        app.set_uninstall_error!

        #
        gex_logger.error('debug_provision', 'after uninstall app - res_app_script - error', {})
        return res_app_script
      end
=end

      # run common provision script
      res_gex_script = app_uninstall_provision_master_gex_script(application_id, sysdata)

      if res_gex_script.error?
        #
        app.set_uninstall_error!

        #
        gex_logger.error('debug_provision', 'error app_uninstall_provision_master_gex_script', {})
        return res_gex_script
      end


      # callbacks
      if callback_after
        gex_logger.debug('debug_provision', 'provision Running callback ', {fn: callback_after})

        #callback_after.call(application_id)
        begin
          res_callback = Gexcore::Applications::Service.send(callback_after.to_sym, application_id)

          if !res_callback
            gex_logger.exception "application provision error", "Callback error"

            res.set_error('application_uninstall_error', 'Cannot provision application', 'Cannot call after script')
            return res
          end
        rescue => e
          gex_logger.exception "application provision error", e

          res.set_error('application_uninstall_error', 'Cannot provision application', 'Cannot call after script')
          return res
        end

      end


      # ok
      res.set_data

      res
    end


    def self.app_uninstall_provision_master_app_script(application_id, sysdata={})
      gex_logger.debug("debug_provision", "app provision - start uninstall master")

      #
      res = Response.new
      res.set_sysdata sysdata

      #
      app = ClusterApplication.find(application_id)
      cluster = app.cluster
      res.sysdata[:application_id] = application_id
      res.sysdata[:cluster_id] = cluster.id


      # run provision
      script = Gexcore::Provision::Service.build_cmd_cap(
          'provision:app_uninstall_master',
          "_cluster_id=#{app.cluster_id} _app_id=#{app.id} "
      )
      res_provision = Gexcore::Provision::Service.run('app_uninstall_master', script)

      # OLD -  2017-05-17
=begin
      # run chef recipe on master
      container_hadoop_master = cluster.get_master_container('hadoop')
      hadoop_master_ipv4 = container_hadoop_master.public_ip

      filename_config = Gexcore::Applications::Service.config_for_application_filename( app)
      recipe = "#{app.name}::master"
      chef_node_name = "master-#{cluster.id}"
      from_dir = File.join(config.chef_dir, 'config-knife/master_node')

      opts = {
          ssh_user: 'root',
          ssh_password: 'vagrant',
      }

      #
      #req = Gexcore::Provision::ChefRequest.new(from_dir, hadoop_master_ipv4, chef_node_name, opts)
      #res_query = req.run(filename_config, recipe)

      cmd = Gexcore::Provision::Service.build_cmd_chef(from_dir, hadoop_master_ipv4, chef_node_name, opts, filename_config, recipe)
      res_provision = Gexcore::Provision::Service.run("app_uninstall_master_app", cmd)
=end


      if res_provision.error?
        # rollback
        #res_provision_clean = Gexcore::Provision::run_script_ansible("rollback_create_cluster.yml", script_params)


        # return error
        res.set_error('application_uninstall_error', 'Cannot provision application', 'Cannot run provision script')

        gex_logger.error('debug_provision', 'Cannot provision application')

        return res
      end

      res.set_data

      res
    end


    # run provision remove_app
    def self.app_uninstall_provision_master_gex_script(application_id, sysdata={})
      gex_logger.debug("debug_provision", "provision master start uninstall - remove_app")

      # res
      res = Response.new
      res.set_sysdata sysdata


      # input
      if application_id.is_a?(Integer)
        app = ClusterApplication.get_by_id(application_id)
      else
        app = application_id
      end

      gex_logger.debug('debug_provision',"run provision remove_app- start", {application_id: app.id})

      # provision
      #args = ansible_script_params_create_app(app)
      #cmd = Gexcore::Provision::Service.build_cmd_ansible "remove_app.yml", args
      #res_provision = Gexcore::Provision::Service.run("remove_app", cmd)

      #app_data = build_params_app_data(app, 'hash')
      script = Gexcore::Provision::Service.build_cmd_cap(
          'provision:remove_app',
          #"_cluster_id=#{app.cluster_id} _app_id=#{app.id} _app_data='#{app_data.to_json}'"
          "_cluster_id=#{app.cluster_id} _app_id=#{app.id} "
      )
      res_provision = Gexcore::Provision::Service.run('remove_app', script)


      if res_provision.error?
        return res.set_error('app_remove_error', 'Cannot remove app', 'Cannot run ansible script remove_app')
      end

      res.set_data
      res
    end


    ### script params
    def self.build_params_app_data(app, format='hash')
      cluster = app.cluster

      # TODO: app with many containers
      #node = app.containers[0].node

      args = {
          'id'=>app.id,
          'name'=>app.name,
          'uid'=> app.uid,

          'cluster_id'=>cluster.id,
          #'node_id' => node.id,

      }

      # containers
      args['containers']=[]
      app.containers.each do |r|
        args['containers'] << {
            id: r.id,
            name: r.name,
            node_id: r.node_id
        }
      end

      # proxy for services
      args['ssh_services'] ||= []
      args['web_services'] ||= []
      args['proxy_services'] ||= []

      app.services.each do |service|
        next unless service.need_proxy?

        #
        if service.protocol=='ssh'
          #args['ssh_port'] = service.port_out
          args['ssh_services'] << {
              service_name: service.name,
              node_id: service.node_id,
              ssh_port: service.port_out
          }
        elsif service.protocol=='http'
          args['web_services'] << {
              service_name: service.name,
              node_id: service.node_id,
              source_port: service.port_out,
              dest_port: service.port_in,
          }
        else
          args['proxy_services'] << {
              service_name: service.name,
              node_id: service.node_id,
              source_port: service.port_out,
              dest_port: service.port_in,
          }
        end
      end

      #
      return Gexcore::Provision::Service.params_hash_format(args, format)
    end

=begin

    def self.ansible_script_params_create_app(app)
      cluster = app.cluster
      node = app.containers[0].node

      args = {
          '_gex_env' => Gexcore::Settings.ansible_gex_env,
          '_app_name'=>app.name,
          '_application_id'=>app.id,
          '_cluster_id'=>cluster.id,
          '_cluster_uid'=>cluster.uid,
          '_cluster_name'=>cluster.domainname,
          '_node_id' => node.id,
          '_node_name' => node.name,
          '_node_number' => node.node_number,
          '_node_type'=>node.node_type_name,

      }

      # proxy for services
      app.services.each do |service|
        next unless service.need_proxy?

        #
        if service.protocol=='ssh'
          args['_ssh_port'] = service.port_out
        else
          args['_web_services'] ||= []
          args['_web_services'] << {
              service_name: service.name,
              source_port: service.port_out,
              dest_port: service.port_in,

          }
        end

      end


      args
    end
=end

  end
end

