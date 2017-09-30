module AppFactoryHelpers

  def get_random_library_app_not_hadoop
    LibraryApplication.where.not("name LIKE 'hadoop%'").first
  end

  def get_random_apphub_app
    Gexcore::Apphub::Service.get_random
  end

  def build_app_settings
    {
        'base.c1' => 'v1',
        'base.c2' => 'v2',
        'nginx.sitename' => 'mysite.com'
    }

  end

  def build_apphub_settings(app)
    {
      'metadata': app['metadata'],
      'services': app['services'],
      'launch_options': app['launch_options']
    }
  end

  def build_app_text_metadata
    text = File.read('spec/data/app_metadata.rb')
    text
  end

  def build_app_metadata_services
    {
        'ssh' => {name: 'ssh', protocol: 'ssh', port: 22},
        'webui' => {name: 'webui', protocol: 'http', port: 8080},
    }
  end

  def stub_app_create_all
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    stub_create_app_all
  end

  def stub_create_app_all
    # stub
    #allow_any_instance_of(Gexcore::Applications::InstallConfig).to receive(:init_from_metadata).and_return(true)


    # no download for metadata
    allow(Gexcore::Applications::Service).to receive(:download_file_from_gex_files).and_return(true)

    # metadata text
    allow_any_instance_of(Gexcore::Applications::Metadata).to receive(:file_text_metadata).and_return(build_app_text_metadata)


    # consul
    allow(Gexcore::Consul::Utils).to receive(:consul_set).and_return(true)

    # provision master
    allow(Gexcore::Provision::Service).to receive(:run).with("app_install_master_app", anything).and_return(Gexcore::Response.res_data)
    allow(Gexcore::Provision::Service).to receive(:run).with('add_app', anything).and_return(Gexcore::Response.res_data)

    # dns
    #allow(Gexcore::Provision::Service).to receive(:run).with('update_container_route', anything).and_return(Gexcore::Response.res_data)


  end

  def stub_app_uninstall
    #
    allow(AppUninstallProvisionMasterWorker).to receive(:perform_async).and_return true

    # consul
    allow(Gexcore::Consul::Utils).to receive(:consul_set).and_return(true)


    # provision
    allow(Gexcore::Provision::Service).to receive(:run).with('remove_app', anything).and_return(Gexcore::Response.res_data)

    #
    allow(Gexcore::Nodes::Control).to receive(:rabbitmq_add_command_to_queue).with(kind_of(Node), 'uninstallApplication', kind_of(Hash)).and_return(Gexcore::Response.res_data)
  end

  def stub_app_remove

  end


  ### create app

  def create_app_installing(cluster=nil, stub=true, app_name=nil)
    if cluster.nil?
      user, cluster = create_user_active_and_create_cluster
    else
      user = cluster.team.users[0]
    end

    if stub
      #
      stub_app_create_all

      allow(user).to receive(:can?).with(:manage, Cluster).and_return(true)

      stub_create_node_all

    end


    # node
    node = create_node(cluster)


    # app
    if app_name
      app_library = LibraryApplication.where(name: app_name).first
    else
      app_library = get_random_library_app_not_hadoop
      app_name = app_library.name
    end

    app_settings = build_app_settings
    services = build_app_metadata_services

    # install app
    res = Gexcore::Applications::Service.install_application_by_user(user, app_name, node.uid, app_settings)

    app = ClusterApplication.get_by_id(res.data[:application_id])


    [app, node, cluster, user]
  end


  def create_app_active(cluster=nil, stub=true, app_name=nil)

    # app - installing
    app, node, cluster, user = create_app_installing(cluster, stub, app_name)


    # notify installed
    Gexcore::NotificationApplicationService.notify_installed(app)


    [app, node, cluster, user]
  end

  def create_app_uninstalling(cluster=nil, stub=true, app_name=nil)
    # app - active
    app, node, cluster, user = create_app_active(cluster, stub, app_name)


    # notify installed
    res = Gexcore::Applications::Service.uninstall_application(nil, app)


    [app, node, cluster, user]
  end

  def create_app_install_error(cluster=nil, stub=true, app_name=nil)
    # app - active
    app, node, cluster, user = create_app_installing(cluster, stub, app_name)

    # notify install_error
    Gexcore::NotificationApplicationService.notify_install_error(app)

    [app, node, cluster, user]
  end

end
