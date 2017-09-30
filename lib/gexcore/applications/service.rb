module Gexcore::Applications
  class Service < Gexcore::BaseService


    ### info
    def self.is_app_hadoop(app)
      app.name =~ /^hadoop/
    end

# ==============================================================

    def self.install_application_by_user_new(user, app_name, node_uid, settings, app_type='gex')
      res = Response.new
      res.sysdata[:user_id] = user.id

      if user.is_a? Integer
        user = User.find(user)
      end
      return res.set_error('', 'User not found') if user.nil?

      node = Node.get_by_uid(node_uid)
      return res.set_error_forbidden('', 'Select a node first', '') if node.nil?

      res.sysdata[:node_id] = node.id
      cluster = node.cluster

      unless user.can? :manage, cluster
        return res.set_error_forbidden('', 'You have no permissions to add application to this cluster.', '')
      end

      env = Gexcore::Applications::ConfigService.build_env(nil, user, node.cluster, node)

      return send("install_#{app_type}_application", res, app_name, env, settings)
    end


    def self.install_gex_application(res, app_name, env, settings)
      res ||= Response.new
      node = env[:node]
      res.sysdata[:node_id] = node.id
      settings ||= {}

      gex_logger.info('application_install', "app creation started, app_name: #{app_name}", {node_id: node.id})

      lib_app = LibraryApplication.get_by_name(app_name)
      return res.set_error_forbidden('', 'Unknown application', '') if lib_app.nil?

      app = ClusterApplication.new(cluster: node.cluster, library_application_id: lib_app.id)
      app.uid = Gexcore::TokenGenerator.generate_application_uid

      base_app_name = generate_base_app_name(lib_app.name)

      app.name = base_app_name
      app.title = lib_app.title
      app.external = false

      app_metadata = Gexcore::Applications::Metadata.new(lib_app.name)
      app_metadata.load

      default_config = Gexcore::Applications::InstallConfig.new(lib_app.name)

      # from metadata
      default_config.init_from_metadata_old(app_metadata)

      # init values from env
      default_config.build_properties(env)


      # fix settings with default values or values from env
      default_properties = default_config.properties
      default_properties.each do |k, v|
        if !settings.has_key?(k) || settings[k]==''
          settings[k] = default_properties[k]
        end
      end

      app.settings = settings.to_hash

      res_db_app = app.save

      unless res_db_app
        return res.set_error("", "Cannot add new application", "Cannot save to db applications")
      end

      app.settings[:app_id] = app.id

      gex_logger.info('application_install', 'app saved - installing status', {app_id: app.id, node_id: node.id})

      app.begin_install!
      res.sysdata[:application_id] = app.id

      res = create_containers_for_app(app, base_app_name, app_metadata, node, res)

      # save data to consul
      app_data = Gexcore::Applications::Provision.build_params_app_data(app, 'hash')
      Gexcore::Consul::Service::update_app_data(app, app_data)

      # config file
      generate_and_save_config_for_app(app)

      gex_logger.info('application_install', 'app - before enqueue provision', {app_id: app.id, node_id: node.id})

      # provision master and node
      res_provision_queue = provision_master_install_app_enqueue(app.id)

      res.set_data({application_id: app.id})
    end


    def self.generate_base_app_name(lib_app_name)
      base_app_name = lib_app_name.downcase.gsub /-/, '_'
      base_app_name.gsub /[^a-z\d_]+/, ''
    end

# ==============================================================

    ### install

    def self.install_application_by_user(user, appname, node_uid, settings, external=false, app_type='gex')
      res = Response.new
      res.sysdata[:user_id] = user.id

      # user
      if user.is_a? Integer
        user = User.find(user)
      end
      return res.set_error('', 'User not found') if user.nil?

      # node
      node = Node.get_by_uid(node_uid)
      return res.set_error_forbidden('', 'Select a node first', '') if node.nil?

      res.sysdata[:node_id] = node.id

      cluster = node.cluster

      # check permissions
      unless user.can? :manage, cluster
        return res.set_error_forbidden('', 'You have no permissions to add application to this cluster.', '')
      end

      #
      env = Gexcore::Applications::ConfigService.build_env(nil, user, node.cluster, node)


      # todo: rewrite this (remove install application)
      #send("install_#{app_type}_application")


      return install_application(res, appname, env, settings,external)
=begin
      if app_type=='compose_app'
        return install_application_new(res, appname, env, settings, external)
      else
        return install_application(res, appname, env, settings,external)
      end
=end
    end


    def self.install_application_new(res, app_id, env, settings, external)
      res ||= Response.new
      node = env[:node]
      settings ||= {}

      #todo: move this to controller
      settings = settings.to_hash_recursive.deep_symbolize_keys

      #app_meta = app_meta(settings[:cred], external)

      app_metadata = Gexcore::Applications::Metadata.new('')
      app_metadata.initialize_new(settings[:cred], external)
      app_metadata.load_new


      return res.set_error_forbidden('', 'Unknown application', '') if app_meta.nil?
      app_settings = app_meta_to_config(app_metadata, settings, env)

      app = ClusterApplication.new(cluster: node.cluster, library_application_id: app_metadata.get_app_short_cred)
      app_name = generate_app_name(app_meta.get_app_info[:name], node.cluster)

      app.name,app.title = app_name
      app.external = external
      app.uid = Gexcore::TokenGenerator.generate_application_uid
      app.settings = app_settings

      res_db_app = app.save
      return res.set_error("", "Cannot add new application", "Cannot save to db applications") unless res_db_app

      app.begin_install!

      res.sysdata[:application_id] = app.id

      #
      res = create_containers_for_app(app, app_meta, node, res)

      # save data to consul
      app_data = Gexcore::Applications::Provision.build_params_app_data(app, 'hash')
      Gexcore::Consul::Service::update_app_data(app, app_data)

      # config file
      generate_and_save_config_for_app(app)

      # start install
      res_status = app.begin_install!

      ## provision master and node
      gex_logger.debug('debug_provision', 'before enqueue provision', {app_id: app.id})

      res_provision_queue = provision_master_install_app_enqueue(app.id)

      # sync provision
      #res_provision = Gexcore::ProvisionService.app_provision_master(app.id)
      #return res.set_error("", "Cannot install app", "Cannot provision") if res_provision.error?

      res.data[:application_id] = app.id

      res
    end


    def self.load_app_meta(cred,external)
      #metafile_url = external ? Gexcore::Apphub::Service.get_metadata_url(cred) : get_app_meta_url(cred)

      # debug
      metafile_url = external ? "http://localhost:3000/apps_meta/metadata.rb" : "http://localhost:3000/apps_meta/#{cred}/#{cred}.rb"

      require 'open-uri'
      text = open(metafile_url) { |f| f.read }
      text
      #meta = JSON.parse(text.to_s) rescue {}
      #meta.deep_symbolize_keys
    end


    def self.app_meta(cred,external)
      meta_hash = load_app_meta(cred, external)

      app_name = meta_hash[:app_info][:name]

      app_metadata = Gexcore::Applications::Metadata.new(app_name)
      app_metadata.load_new(meta_hash)
      app_metadata
    end


    # app_meta + settings = app_config
    def self.app_meta_to_config(app_meta, settings, env)
      appname = app_meta.get_app_info[:name]
      default_config = Gexcore::Applications::InstallConfig.new(appname)

      # from metadata
      default_config.init_from_metadata(app_meta)

      # init values from env
      default_config.build_properties(env)


      # fix settings with default values or values from env
      default_properties = default_config.properties


      # todo
      default_properties.each do |k, v|
        if !settings.has_key?(k) || settings[k]==''
          settings[k] = default_properties[k]
        end
      end

      # add app_info to settings
      settings[:app_info] = app_meta.get_app_info

      settings
    end


    def self.create_containers_for_app(app, base_app_name, app_meta, node, res)

      container_ids = []
      containers = [{name: base_app_name}] # todo: tmp (for the multi-containers apps in the future)
      return if containers.nil? || containers.empty?

      services = app_meta.get_services

      containers.each do |cont|

        container_basename = base_app_name
        container_name = build_container_name_for_application(container_basename, node)

        container_data = {hostname: container_calc_domain_by_name(container_name)}
        container_id = Gexcore::Containers::Container.create_container_on_node(container_basename, container_name, app, node, container_data)
        return res.set_error("", "Cannot create container", "cannot add row to containers") if container_id.nil?

        container_ids.push(container_id)
        container = ClusterContainer.get_by_id(container_id)

        next if services.nil? || services.empty?
        res = add_services_to_container(app, container, services, res)
        return res if res.error?
      end

      # OK
      res.data[:container_ids] = container_ids
      res.res = true

      res
    end


    def self.add_services_to_container(app, container, services, res)
      services.each do |service_name, service_info|
        # add to db
        name = service_name
        service_id = Gexcore::ClusterServices::Service.create_service(name, app, container, {})
        return res.set_error("", "Cannot add new service", "Cannot save to db services") if service_id.nil?

        # update service data
        service = ClusterService.get_by_id(service_id)
        service_data = build_service_endpoint(service, service_info)
        res_db_update_service = Gexcore::ClusterServices::Service.update_service(service, service_data)
        return res.set_error("", "Cannot set service", "Cannot save to db services - data") unless res_db_update_service
      end

      res.set_data
    end

=begin
    def self.generate_app_name(appname, cluster)
      #todo: fix it!
      name = appname
      i = 0
      until cluster.applications.where(name: name).empty?
        name = appname
        name = name+i.to_s
        i += 1
      end

      name.downcase.gsub(/-/, '_').gsub(/[^a-z\d_]+/, '')
    end
=end

    def self.install_application(res, app_name, env, settings,external)
      res ||= Response.new

      node = env[:node]

      res.sysdata[:node_id] = node.id

      #
      settings ||= {}

      # app
      lib_app = external ? Gexcore::Apphub::Service.get_by_id(app_name) : LibraryApplication.get_by_name(app_name)

      # old > library_app = LibraryApplication.get_by_name(app_name)
      return res.set_error_forbidden('', 'Unknown application', '') if lib_app.nil?


      lib_app_id = external ? lib_app['id'] : lib_app.id
      lib_app_name = external ? lib_app['name'] : lib_app.name

      app = ClusterApplication.new(cluster: node.cluster, library_application_id: lib_app_id)
      app.uid = Gexcore::TokenGenerator.generate_application_uid

      base_app_name = lib_app_name.downcase.gsub /-/, '_'
      base_app_name.gsub! /[^a-z\d_]+/, ''
      #base_app_name = external ? base_app_name+"_#{app.uid}" : lib_app_name+"_#{app.uid}"
      base_app_name = lib_app_name

      app.name = base_app_name
      app.title = external ? lib_app_name : lib_app.title
      app.external = external

      # app settings
      app_metadata = Gexcore::Applications::Metadata.new(lib_app_name)


      #todo: wtf -> remove it!!!
      if external

        settings = settings.to_hash_recursive

        settings = settings.to_hash.symbolize_keys
        settings[:metadata] = settings[:metadata].deep_symbolize_keys
        settings[:services] = settings[:services].deep_symbolize_keys
      end


      if external
        if lib_app[:application_type] == 'compose_app'
          app_metadata.load_compose(app_name,settings)
        else
          app_metadata.load_external(app_name,settings)
        end
      else
        app_metadata.load
      end

      #
      default_config = Gexcore::Applications::InstallConfig.new(lib_app_name)

      # from metadata
      default_config.init_from_metadata_old(app_metadata)

      # init values from env
      default_config.build_properties(env)


      # fix settings with default values or values from env
      default_properties = default_config.properties
      default_properties.each do |k, v|
        if !settings.has_key?(k) || settings[k]==''
          settings[k] = default_properties[k]
        end
      end

      app.settings = settings.to_hash

      #
      res_db_app = app.save
      return res.set_error("", "Cannot add new application", "Cannot save to db applications") if !res_db_app

      # todo -> tmp - save app id in settings
      app.settings[:app_id] = app.id

      gex_logger.debug('debug_provision', 'app saved', {app_id: app.id})


      app.begin_install!

      res.sysdata[:application_id] = app.id


      #### todo: rewrite this part for compose apps

      # if compose_app
      if external && lib_app && lib_app[:application_type] == 'compose_app'
        lib_app.symbolize_keys!
        compose_app = lib_app

        compose_app[:services].each do |compose_container|

          cc_name = compose_container[0]
          container_basename = cc_name+'_'+base_app_name
          container_name = build_container_name_for_application(container_basename, node)
          container_data = {hostname: container_calc_domain_by_name(container_name)}
          container_id = Gexcore::Containers::Container.create_container_on_node(container_basename, container_name, app, node, container_data)
          return res.set_error("", "Cannot create container", "cannot add row to containers") if container_id.nil?

          container = ClusterContainer.get_by_id(container_id)

          if compose_container[1]['ports'] && !compose_container[1]['ports'].empty?

            services = Gexcore::Apphub::Service.ports_to_services(compose_container[1]['ports'],container.name)

            services.each do |service_name, service_info|
              # add to db
              name = service_info[:name]
              service_id = Gexcore::ClusterServices::Service.create_service(name, app, container, {})
              return res.set_error("", "Cannot add new service", "Cannot save to db services") if service_id.nil?

              # update service data
              service = ClusterService.get_by_id(service_id)
              service_data = build_service_endpoint(service, service_info)
              res_db_update_service = Gexcore::ClusterServices::Service.update_service(service, service_data)
              return res.set_error("", "Cannot set service", "Cannot save to db services - data") if !res_db_update_service
            end
          end
        end
      else
        # create container
        container_basename = base_app_name
        container_name = build_container_name_for_application(container_basename, node)
        container_data = {hostname: container_calc_domain_by_name(container_name)}
        container_id = Gexcore::Containers::Container.create_container_on_node(container_basename, container_name, app, node, container_data)
        return res.set_error("", "Cannot create container", "cannot add row to containers") if container_id.nil?

        res.sysdata[:container_id] = container_id

        container = ClusterContainer.get_by_id(container_id)


        services = app_metadata.get_services

        # todo: serivce_name - unused
        services.each do |service_name, service_info|
          # add to db
          name = service_info[:name]
          service_id = Gexcore::ClusterServices::Service.create_service(name, app, container, {})
          return res.set_error("", "Cannot add new service", "Cannot save to db services") if service_id.nil?

          # update service data
          service = ClusterService.get_by_id(service_id)
          service_data = build_service_endpoint(service, service_info)
          res_db_update_service = Gexcore::ClusterServices::Service.update_service(service, service_data)
          return res.set_error("", "Cannot set service", "Cannot save to db services - data") if !res_db_update_service
        end


      end


      # save data to consul
      app_data = Gexcore::Applications::Provision.build_params_app_data(app, 'hash')
      Gexcore::Consul::Service::update_app_data(app, app_data)


      # config file
      generate_and_save_config_for_app(app)

      # start install
      res_status = app.begin_install!


      ## provision master and node
      gex_logger.debug('debug_provision', 'before enqueue provision', {app_id: app.id})

      res_provision_queue = provision_master_install_app_enqueue(app.id)

      # sync provision
      #res_provision = Gexcore::ProvisionService.app_provision_master(app.id)
      #return res.set_error("", "Cannot install app", "Cannot provision") if res_provision.error?



      #old
      #res.set_data({container_id: container_id, application_id: app.id})
      #todo:
      #res.set_data({container_ids: [....], application_id: app.id})

      # tmp
      res.set_data({application_id: app.id})
    end



    ### uninstall

    def self.uninstall_application_by_user(user, app_uid)
      res = Response.new
      res.sysdata[:user_id] = user.id

      # user
      if user.is_a? Integer
        user = User.find(user)
      end
      return res.set_error('', 'User not found') if user.nil?

      # app
      app = ClusterApplication.get_by_uid(app_uid)
      return res.set_error_forbidden('', 'Application not set', '') if app.nil?

      res.sysdata[:application_id] = app.id

      #
      cluster = app.cluster

      # check permissions
      if !(user.can? :manage, app.cluster)
        return res.set_error_forbidden('', 'You have no permissions to manage application', '')
      end

      # change app status
      if app.removed?
        return res.set_error('app_uninstall_not_found', 'Application is removed', 'try to uninstall removed app', 404)
      end

      #
      return uninstall_application(res, app)
    end

    def self.uninstall_application(res, app)
      if Gexcore::Applications::Service.is_app_hadoop(app)
        # remove hadoop
        return Gexcore::AppHadoop::App.uninstall(res, app)
      else
        # user app
        return uninstall_application_not_hadoop(res, app)
      end
    end


    def self.uninstall_application_not_hadoop(res, app)
      res ||= Response.new

      res.sysdata[:cluster_id] = app.cluster_id
      res.sysdata[:application_id] = app.id

      # status = uninstalling
      res_status = app.begin_uninstall!
      return res.set_error("app_uninstall_error", "Cannot start uninstall of application", "Cannot update status") if !res_status

      # containers
      begin
        app.containers.w_not_deleted.all.each do |container|
          res_status = container.begin_uninstall!
          raise "Cannot change container status" if !res_status
        end
      rescue => e
        app.set_uninstall_error!

        return res.set_error("app_uninstall_error", "Cannot uninstall containers of application", "Cannot update container status") if !res_status
      end

      # provision master and node
      res_provision_queue = provision_master_uninstall_app_enqueue(app.id)

      # send command to gexd
      action_params = {applicationID: app.uid, applicationName: app.name}
      app.containers.each do |container|
        node = container.node

        res_command = Gexcore::Nodes::Control.rabbitmq_add_command_to_queue(
            node,
            'uninstallApplication',
            action_params.merge({containerName: container.name}))

        if res_command.error?
          app.set_uninstall_error!

          return Response.res_error("app_uninstall_error", 'Cannot send command to node')
        end

      end


      #
      res.set_data({application_id: app.id})
    end



    def self.uninstall_error_application(app)

      # containers
      app.containers.each do |container|
        res_status = container.set_uninstall_error!
      end

      return true
    end



    def self.after_provision_master_uninstall_app(application_id)


      return true
    end


    ### remove

    def self.remove_application_by_user(user, app_uid)
      res = Response.new
      res.sysdata[:user_id] = user.id

      #
      if app_uid.is_a? ClusterApplication
        app = app_uid
      else
        app = ClusterApplication.get_by_uid app_uid
      end

      return res.set_error_badinput('', 'Application not found', '') if app.nil?

      #
      res.sysdata[:application_id] = app.id

      # check permissions
      if !(user.can? :manage, app.cluster)
        return res.set_error_forbidden('', 'You have no permissions to remove application', '')
      end


      # do the work
      return remove_application(app)
    end




    def self.remove_application(app)
      res = Response.new

      container = app.containers.first
      node = container.node

      res.sysdata[:cluster_id] = app.cluster_id
      res.sysdata[:node_id] = node.id if node

      # start removing
      res_status = app.begin_remove!
      return res.set_error('application_remove_error', 'Cannot change application status', '') if !res_status


      # do the work
      begin

        # remove containers
        res_containers = remove_all_containers_for_app(app)

        if res_containers.error?
          res.set_error("application_remove_error", 'Cannot delete containers', 'cannot delete Containers in DB')
          raise 'error'
        end

        # ok
        res.set_data
      rescue => e
        if res.success?
          res.set_error_exception('Cannot remove application', e)
        end
      end

      if res.error?
        app.set_remove_error!
        return res
      end

      # status removed
      res_status = app.finish_remove!
      return  res.set_error("application_change_status_error", 'Cannot change application status',"error changing status") if !res_status

      #
      res.set_data
    end


    def self.remove_all_containers_for_app(app)

      begin
        app.containers.w_not_deleted.all.each do |container|
          Gexcore::Containers::Container.remove_container(container)
        end
      rescue => e
        gex_logger.exception "cannot delete containers", e, {application_id: app.id}

        res = Response.res_error_exception('Error', e)
        return res
      end

      # OK
      gex_logger.debug "debug_delete_containers", "containers removed", {application_id: app.id}

      Response.res_data
    end



    ### operations

    def self.do_before_installed(app)

      # status for containers
      containers = app.containers.all
      containers.each do |container|
        res_container_status = container.finish_install
        container.save
      end

      return true
    end


    def self.do_after_installed(app)
      # make active
      app.set_active!

      return true
    end



    def self.do_before_activated(app)
      # status for containers
      containers = app.containers.all
      containers.each do |container|
        res_container_status = container.set_active
        container.save
      end

      return true
    end



    def self.do_before_install_error(app)
      # status for containers
      containers = app.containers.all
      containers.each do |container|
        res_container_status = container.set_install_error
        container.save
      end

      return true
    end


    ### uninstall
    def self.do_after_uninstalled(app)
      # remove
      return remove_application(app)
    end



    ### services

    def self.build_service_endpoint(service, service_info)
      cluster = service.container.cluster
      container = service.container

      data  = {
          name: service.name,
          title: service_info[:title],

          hostname: container.hostname,
          url: service_info[:url],
          protocol: service_info[:protocol],
          port_in: service_info[:port],
          #port_out: service_info[:port],
          port_out: build_service_port_out(service, service_info),
          #port_out: build_service_port_out(service, service_info[:port]),

      }


      data
    end

    def self.build_service_port_out(service, service_info)
      if service.need_proxy?(service_info)
        return build_service_port_out_proxy(service, service_info)
      else
        return service_info[:port]
      end
    end

    def self.build_service_port_out_proxy(service, service_info)
      5000+service.id
    end


    ### provision master node

    def self.provision_master_install_app_enqueue(application_id)
      AppProvisionMasterWorker.perform_async(application_id, get_env)
      return Response.res_data
    end


    def self.provision_master_uninstall_app_enqueue(application_id)
      res_task = AppUninstallProvisionMasterWorker.perform_async(application_id, get_env)
      return Response.res_data
    end


    ###

    def self.after_provision_master_install_app(application_id)

      gex_logger.debug("debug_provision", "after_provision_master_install_app")
      app = ClusterApplication.get_by_id(application_id)

      container = app.containers.first
      node = container.node

      # send command to gexd on node
      app_name = nil
      app_name ||= app.library_application.name rescue nil

      p={
          nodeID: node.uid,
          applicationID: app.uid,
          applicationName: app_name,
          containerName: container.name,
          external: app.external
      }
      gex_logger.debug("debug_provision", "before send cmd to node", {p: p})
      return Gexcore::Nodes::Control.send_command_to_node(node, 'installApplication', p)
    end






    # add new row to table cluster_applications
    def self.add_application_to_cluster(app_name, cluster)
      res = Response.new

      library_app = LibraryApplication.get_by_name app_name
      return res.set_error_badinput("", "Application not found", "bad app name #{app_name}") if library_app.nil?

      row = ClusterApplication.new(name: app_name, cluster: cluster, library_application: library_app)
      row.uid = Gexcore::TokenGenerator.generate_application_uid
      res_db = row.save

      return res.set_error("hadoop_install_error", "Cannot add Hadoop", "Cannot save to db applications") if !res_db

      res.set_data({application_id: row.id})
    end



    def self.build_container_name_for_application(app_name, node)
      # TODO: add $appname-2, $appname-3 if this application has other containers on this node
      return app_name+"-"+node.name
    end






    ### config

    def self.generate_and_save_config_for_container(container, app)
      # todo fix!!!
      filename = config_for_application_filename(container, app, 'plain')
      filename_tree = config_for_application_filename(container, app, 'tree')

      # plain
      File.open(filename, 'w+') do |file|
        file.write(app.settings.to_json)
      end

      # hash tree
      data = Gexcore::Applications::InstallConfig.build_tree_from_plain(app.settings)
      File.open(filename, 'w+') do |file|
        file.write(data.to_json)
      end
    end

    def self.generate_and_save_config_for_app(app)
      # save to consul
      data = Gexcore::Applications::InstallConfig.build_tree_from_plain(app.settings)
      Gexcore::Consul::Service.update_app_settings(app, data)

      # save to files
      filename = config_for_application_filename(app, 'plain')
      filename_tree = config_for_application_filename(app, 'tree')

      # plain
      File.open(filename, 'w+') do |file|
        file.write(app.settings.to_json)
      end

      # hash tree
      data = Gexcore::Applications::InstallConfig.build_tree_from_plain(app.settings)
      File.open(filename, 'w+') do |file|
        file.write(data.to_json)
      end


    end





    def self.app_current_version(app_name)
      url = app_url_version(app_name)

      require 'open-uri'
      contents = nil
      begin
        gex_logger.debug("debug_app_version", "url: #{url}")

        Timeout.timeout 5 do
          x = ''
          open(url){|f| x=f.meta  }

          contents = open(url).read

          gex_logger.debug("debug_app_version", "meta: #{x}")
          gex_logger.debug("debug_app_version", "contents: #{contents}")
        end
      rescue Timeout::Error
        gex_logger.debug("debug_app_version", "timeout")
        contents = nil
      rescue => e
        gex_logger.debug("debug_app_version", "e: #{e}")
        contents = nil
      end
      return nil if contents.nil?

      #gex_logger.debug("debug_app_version", "c: #{contents}")
      #v = contents.strip.gsub /^version=/im, ''
      #app_meta = JavaProperties.parse(contents)

      doc = (IniParse.parse(contents) rescue nil)
      return nil if doc.nil?

      v = (doc['__anonymous__']['version'] rescue nil)

      gex_logger.debug("debug_app_version", "v: #{v}")

      v
    end

    def self.app_url_version(app_name)
      #app_repo_basedir+'/'+app_name+'-version.txt'
      config.server_app_repo_versions+'/'+app_name+'-version.txt'
    end

    def self.app_download_url(app_name, version)
      url = app_repo_basedir+'gex-'+app_name+'-'+version+'.tar.gz'
    end


    def self.app_repo_basedir
      config.server_app_repo+'/'
    end


    def self.download_file_from_gex_files(url, filename)
      require 'open-uri'
      open(filename, 'wb') do |file|
        file << open(url).read
      end
    end


    ### filenames


    def self.config_for_application_filename(app, format='plain')
      #
      dir = app_properties_dir(app)
      FileUtils.mkdir_p(dir) unless File.exists?(dir)

      #basefilename = "config.json"
      #basefilename = "config.plain.json" if format=='plain'

      f = File.join(dir, 'config.json')

      File.expand_path(f)
    end

    # not used
    def self.app_properties_base_dir(container, app)
      File.join(config.dir_clusters_data, "#{container.cluster_id}/applications/#{app.id}")
    end

    def self.app_properties_dir(app)
      File.join(config.dir_clusters_data, "#{app.cluster_id}/applications/#{app.id}")
    end

    ### domain

    def self.parse_domain(domain,node_name='')
      zone = config.domain_zone

      if domain =~ /^([a-z0-9\_\d]+)-([a-z0-9\-]+)\.#{zone}$/i
        #container_basename, p_node = $1, $2
        #container_name = "#{container_basename}-#{p_node}"

        container_basename = domain.gsub(".#{zone}","").gsub("-#{node_name}","").gsub("-","_")
        container_name = "#{container_basename}-#{node_name}"

        return {
            container_name: container_name,
            container_basename: container_basename,
            node_name: node_name,
        }
      end

      {}
    end


    def self.container_calc_domain_by_name(container_name)
      "#{container_name.gsub('_','-')}.#{config.domain_zone}"
    end


    def self.get_app_meta_url(id)
      # todo > link to our app config
    end

  end
end
