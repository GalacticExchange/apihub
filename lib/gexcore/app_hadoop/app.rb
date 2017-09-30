module Gexcore::AppHadoop
  class App < Gexcore::BaseService

    # master
    SERVICES_MASTER = {
        'ssh' => {protocol: 'ssh', port: 22},
        'hadoop_resource_manager' => {protocol: 'http', port: 8088},
        'hdfs' => {protocol: 'hdfs', port: 8020},
        'hdfs_namenode_webui' => {protocol: 'http', port: 50070},
        'hue' => {protocol: 'http', port: 8000},
        'spark_master_webui' => {protocol: 'http', port: 18081},
        'spark_history' => {protocol: 'http', port: 18080},
        'elastic' => {protocol: 'http', port: 9200},
        'kudu' => {protocol: 'http', port: 8051},
        'impala' => {protocol: 'http', port: 25000}

    }

    CONTAINERS_BY_SERVICE_MASTER = {
        'ssh' => 'hadoop',
        'hadoop_resource_manager' => 'hadoop',
        'hdfs' => 'hadoop',
        'hdfs_namenode_webui' => 'hadoop',
        'hue' => 'hue',
        'spark_master_webui' => 'hadoop',
        'spark_history' => 'hadoop',
        'elastic' => 'hadoop',
        'kudu' => 'hadoop',
        'impala' => 'hadoop'
    }


    # services on slave node
    SERVICES_SLAVE = {
        'ssh' => {protocol: 'ssh', port: 22},
        'hdfs' => {protocol: 'hdfs', port: 8020},
        #'hdfs_namenode_webui' => {protocol: 'http', port: 50070},
        'hue' => {protocol: 'http', port: 8000},
        'kibana' => {protocol: 'http', port: 5601},
        'elastic' => {protocol: 'http', port: 9200},
        'nifi' => {protocol: 'http', port: 8080},
        'neo4j' => {protocol: 'http', port: 7474},
        'neo4j_bolt' => {protocol: 'bolt', port: 7687},
        'kudu' => {protocol: 'http', port: 8050},
        'metabase' => {protocol: 'http', port: 3000},
        'superset' => {protocol: 'http', port: 8088}
    }

    CONTAINERS_BY_SERVICE_SLAVE = {
        'ssh' => 'hadoop',
        'hdfs' => 'hadoop',
        #'hdfs_namenode_webui' => 'hadoop',
        'hue' => 'hue',
        'kibana' => 'hadoop',
        'elastic' => 'hadoop',
        'nifi' => 'hadoop',
        'neo4j' => 'hadoop',
        'neo4j_bolt' => 'hadoop',
        'kudu' => 'hadoop',
        'metabase' => 'hadoop',
        'superset' => 'hadoop'
    }

    ### get

    def self.get_container_master(app)
      container = app.containers.master_containers.w_not_deleted.first
    end


    ### INSTALL

    ### hadoop app in cluster

    def self.create_hadoop_application(app_name, cluster)
      res = Response.new

      res_db = Gexcore::Applications::Service.add_application_to_cluster(app_name, cluster)
      #raise 'Cannot create application Hadoop' if res_db.error?
      return res_db if res_db.error?

      #
      app = ClusterApplication.get_by_id(res_db.data[:application_id])

      res.sysdata[:application_id] = app.id

      # update cluster.hadoop_app
      cluster.hadoop_app_id = app.id
      db_saved = cluster.save

      return res.set_error("hadoop_install_error", "Cannot add Hadoop", "Cannot update DB: clusters") if !db_saved


      # status - installing
      app.begin_install!

      # install app hadoop
      res_app_install = Gexcore::AppHadoop::App.install_on_master_node(app, cluster)
      #raise 'Cannot install application Hadoop' if res_app_install.error?
      return res_app_install if res_app_install.error?

      #
      res.set_data({application_id: app.id})
      res
    end


    # filter SERVICES_MASTER or SERVICES_SLAVE for cluster
    def self.filer_services_cluster_components(cluster, services)

      cluster_components = cluster.get_option('components')
      all_components_names = Gexcore::Clusters::Components.get_all_components_names

      # if service in all_components but not in cluster_components -> reject
      res = services.select do |service_name, service_info|
        !all_components_names.include?(service_name) || (all_components_names.include?(service_name) && cluster_components.include?(service_name))
      end

      res
    end


    # app - AR object, cluster - AR object
    def self.install_on_master_node(app, cluster)
      res = Response.new

      gex_logger.debug('hadoop_install_start', 'Installing Hadoop', {cluster_id: cluster.id})


      #
      app_name = app.name

      # containers
      containers = {}

      # hadoop container
      container_name = 'hadoop'
      res_container = create_container_master(container_name, app, cluster)
      return res_container if res_container.error?
      containers[container_name] = ClusterContainer.get_by_id(res_container.data[:container_id])

      # hue container
      container_name = 'hue'
      res_container = create_container_master(container_name, app, cluster)
      return res_container if res_container.error?
      containers[container_name] = ClusterContainer.get_by_id(res_container.data[:container_id])

      # services
      services = filer_services_cluster_components(cluster, SERVICES_MASTER)
      services.each do |service_name, service_info|
        container = containers[CONTAINERS_BY_SERVICE_MASTER[service_name]]

        # add to db
        service_id = Gexcore::ClusterServices::Service.create_service(service_name, app, container, {})
        return res.set_error("hadoop_install_error", "Cannot add new service", "Cannot save to db services") if service_id.nil?

        # update service data
        service = ClusterService.get_by_id(service_id)
        service_data = build_service_endpoint_master(service)
        res_db_update_service = Gexcore::ClusterServices::Service.update_service(service, service_data)
        return res.set_error("hadoop_install_error", "Cannot set service", "Cannot save to db services - data") if !res_db_update_service

      end

      # provision
      res_provision = Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script_enqueue(app.id)
      return res.set_error("cluster_provision_error", "Cannot provision master node", "Cannot provision master node") if res_provision.error?


      res.set_data({application_id: app.id})
    end



    # add new container for master
    def self.create_container_master(container_basename, app, cluster)
      res = Response.new

      #
      uid = Gexcore::AppHadoop::MasterContainer.generate_uid(container_basename, cluster)
      ip = Gexcore::AppHadoop::MasterContainer.calc_ip(container_basename, cluster)
      container_name = "#{container_basename}-#{cluster.id}"
      hostname = Gexcore::AppHadoop::MasterContainer.calc_domain(container_basename, cluster)
      data = {
          basename: container_basename,
          uid: uid,
          private_ip: ip,
          hostname: hostname
      }

      # DB
      container_id = Gexcore::Containers::Container.create_container_master(container_name, app, cluster, data)

      return res.set_error("", "Cannot create container", "cannot add row to db containers") if container_id.nil?

      res.set_data({container_id: container_id})
    end


    ### install on slave node

    def self.install_on_slave_node(app, node)
      res = Response.new

      #gex_logger.debug("hadoop_install_start", "Installing Hadoop on Node", {node_id: node.id})

      #
      app_name = app.name

      # containers
      containers = {}

      # hadoop container - container in DB
      container_name = 'hadoop'
      res_container = create_container_node(container_name, app, node)
      return res_container if res_container.error?
      containers[container_name] = ClusterContainer.get_by_id(res_container.data[:container_id])

      # hue container - container in DB
      container_name = 'hue'
      res_container = create_container_node(container_name, app, node)
      return res_container if res_container.error?
      containers[container_name] = ClusterContainer.get_by_id(res_container.data[:container_id])


      # services
      services = filer_services_cluster_components(node.cluster, SERVICES_SLAVE)
      services.each do |service_name, service_info|
        container = containers[CONTAINERS_BY_SERVICE_SLAVE[service_name]]

        # add to db
        service_id = Gexcore::ClusterServices::Service.create_service(service_name, app, container, {})
        return res.set_error("", "Cannot add new service", "Cannot save to db services") if service_id.nil?

        # update service data
        service = ClusterService.get_by_id(service_id)
        service_data = build_service_endpoint_slave(service)
        res_db_update_service = Gexcore::ClusterServices::Service.update_service(service, service_data)
        return res.set_error("", "Cannot set service", "Cannot save to db services - data") if !res_db_update_service

      end

      #
      gex_logger.debug("hadoop_application_created", "Hadoop application created", {node_id: node.id})



      #
      res.set_data({application_id: app.id})
    end



    # add new container for slave
    def self.create_container_node(container_basename, app, node)
      res = Response.new

      #
      uid = Gexcore::AppHadoop::SlaveContainer.generate_uid(container_basename, node)

      container_name = container_basename + '-'+node.name
      data = {
          basename: container_basename,
          uid: uid,
          public_ip: Gexcore::AppHadoop::SlaveContainer.allocate_ip(node),
          hostname: Gexcore::AppHadoop::SlaveContainer.calc_domain(container_basename, node),
      }

      # DB
      container_id = Gexcore::Containers::Container.create_container_on_node(container_basename, container_name, app, node, data)

      return res.set_error("", "Cannot create container", "cannot add row to db containers") if container_id.nil?

      res.set_data({container_id: container_id})
    end







    ### UNINSTALL app

    def self.uninstall(res, app)
      res ||= Response.new

      res.sysdata[:application_id] = app.id
      res.sysdata[:cluster_id] = app.cluster_id


      #
      cluster = app.cluster

      #
      gex_logger.info('hadoop_uninstall_start', 'Uninstalling Hadoop', {cluster_id: cluster.id})

      # status = uninstalling
      res_status = app.begin_uninstall!
      return res.set_error("hadoop_uninstall_error", "Cannot start uninstall of Hadoop", "Cannot update status") if !res_status


      # provision master
      res_provision = Gexcore::Clusters::Provision.provision_master_remove_cluster(app)

      if res_provision.error?
        app.set_uninstall_error!

        return res.set_error("hadoop_uninstall_error", "Cannot provision master node", "Cannot provision master")
      end

      # OK
      res_install = app.finish_uninstall!

      if !res_install
        return res.set_error("hadoop_uninstall_error", "Cannot change Hadoop status", "Cannot change status")
      end

      gex_logger.info('hadoop_uninstalled', 'Hadoop uninstalled', {cluster_id: cluster.id})

      # containers
      #containers = app.containers.all
      #containers.each do |container|
      #  container.set_active!
      #end


      res.set_data({application_id: app.id})
    end



    ### helpers

    def self.build_service_endpoint(service)
      app = service.application
      container = service.container

      if app.container.is_master
        # master node
        return build_service_endpoint_master(service)
      else
        # slave node
        return build_service_endpoint_slave(service)
      end

    end

    def self.build_service_endpoint_master(service)
      cluster = service.container.cluster
      container = service.container
      service_info = SERVICES_MASTER[service.name]

      data  = {
          name: service.name,
          #title: service_port.service.title,

          #public_ip: AppHadoop::MasterContainer.get_public_ip(container_name, cluster),
          #private_ip: AppHadoop::MasterContainer.get_private_ip(container_name, cluster),
          #hostname: AppHadoop::MasterContainer.calc_domain(container.name, cluster),
          hostname: container.hostname,
          #proxy_host: AppHadoop::MasterContainer.calc_domain_proxy(container_name, service_port),

          protocol: service_info[:protocol],
          port_in: service_info[:port],
          port_out: build_service_port_out(service),

      }


      data
    end


    def self.build_service_port_out(service)
      5000+service.id
    end

    def self.build_service_endpoint_slave(service)
      cluster = service.container.cluster
      container = service.container
      node = container.node
      service_info = SERVICES_SLAVE[service.name]

      data  = {
          name: service.name,
          #title: service_port.service.title,

          #public_ip: AppHadoop::SlaveContainer.get_public_ip(container_name, cluster),
          #private_ip: AppHadoop::SlaveContainer.get_private_ip(container_name, cluster),
          #hostname: AppHadoop::SlaveContainer.calc_domain(container.basename, node),
          hostname: container.hostname,

          protocol: service_info[:protocol],
          port_in: service_info[:port],
          port_out: build_service_port_out_slave(service),
      }


      data
    end

    def self.build_service_port_out_slave(service)
      service_info = SERVICES_SLAVE[service.name]

      node = service.node

      # not proxy for onprem node
      if node.node_type_name==ClusterType::ONPREM
        return service_info[:port]
      elsif node.node_type_name==ClusterType::AWS
        return build_service_port_out_slave_aws(service)
      end

    end

    def self.build_service_port_out_slave_aws(service)
      5000+service.id
    end



    ### endpoints

    def self.get_master_endpoints(app)
      return {} if app.nil?

      cluster = app.cluster

      # master endpoints
      endpoints = {}

      services =  cluster.services.where(node_id: nil).includes(:container, :library_service).all
      #service_ports =  Gexcore::Clusters::Service.get_ports_by_service(cluster)

      #service_ports.each do |service_name, service_port|
      services.each do |service|
        #container_name = AppHadoop::MasterContainer.get_container_name_for_service(service_name)
        container_name = service.container.name

        endpoints[service.name] = {
            name: service.name,
            title: service.name,
            public_ip: service.container.get_local_ip,
            host: MasterContainer.calc_domain(container_name, cluster),
            protocol: service.protocol,
            port: service.port_in,
            port_out: service.port_out,
            proxy_host: MasterContainer.calc_domain_proxy(container_name, service),
        }

      end

      endpoints
    end




    ### endpoints for node

    def self.get_node_endpoints(app, node)
      return {} if app.nil?

      cluster = app.cluster

      # endpoints
      endpoints = {}

      services =  cluster.services.where(node_id: node.id).includes(:container, :library_service).all

      services.each do |service|
        #container_name = service.container.name

        endpoints[service.name] = {
            name: service.name,
            title: service.name,
            public_ip: service.container.get_local_ip,
            private_ip: service.container.get_gex_ip,
            host: AppHadoop::SlaveContainer.calc_domain(service.container.name, cluster),
            protocol: service.protocol,
            port: service.port_in,
            port_out: service.port_out,
            #proxy_host: AppHadoop::MasterContainer.calc_domain_proxy(container_name, service),
        }

      end

      endpoints

      #### OLD
      #endpoints['hadoop_ssh'] = hadoop_ssh_node_endpoint(node)
      #endpoints['hadoop_hue'] = hue_node_endpoint(node)
    end

=begin
    def self.hadoop_ssh_node_endpoint(node)
      ip = Gexcore::Containers::Service.get_ip_of_container().get_public_ip('hadoop', node)
      domain = AppHadoopSlaveContainer.calc_domain('hadoop', node)
      port = 22

      {
          name: 'hadoop_ssh',
          title: "SSH",
          protocol: 'ssh',
          ip: ip,
          host: domain,
          port: port,
          url: "",
      }
    end

    def self.hue_node_endpoint(node)
      ip = ServiceNodeContainer.get_ip('hue', node)
      domain = ServiceNodeContainer.calc_domain('hue', node)
      port = 8000

      {
          name: 'hadoop_hue',
          title: "Hue",
          protocol: 'http',
          ip: ip,
          host: domain,
          port: port,
          url: "http://#{domain}:#{port}"
      }
    end
=end



  end
end

