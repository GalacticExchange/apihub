module Gexcore::Nodes
  class Service < Gexcore::BaseService

    ### node info
    def self.get_node_info_by_user(user, node_uid, opts={})
      # check input
      if node_uid.blank?
        return Response.res_error_badinput("", "Node not set")
      end

      node = Node.get_by_uid node_uid
      if node.nil?
        #return Response.res_error_badinput("", "Node not found")
        return Response.res_error("", "Node not found", "node info - node not found", 404)
      end


      # check removed
      if node.removed? && !opts[:with_removed]
        return Response.res_error("", "Node not found", "node info - node removed", 404)
      end


      # check permissions
      if !(user.can? :view_node_info, node)
        return Response.res_error_forbidden("view_node_error", 'No permissions to view this node')
      end


      # work
      #data = node.to_hash

      Response.res_data({node: node})
    end


    def self.get_node_info_by_agent(agent_node_id, node_uid)
      # check input
      if node_uid.blank?
        return Response.res_error_badinput("", "Node not set")
      end

      node = Node.get_by_uid node_uid
      if node.nil?
        return Response.res_error("", "Node not found", "node info - node not found", 404)
      end

      # check permissions
      if agent_node_id!=node.id
        return Response.res_error_forbidden("view_node_error", 'No permissions to view this node')
      end


      # work
      #data = node.to_hash

      Response.res_data({node: node})
    end


    ### all info about node

    def self.get_node_info_all(node)
      res = {}

      res['node_id'] = node.id
      res['node_uid'] = node.uid

      #
      services_hadoop = Gexcore::ClusterServices::Service.get_service_info_hadoop(node.cluster, node)

      # master
      prefix = 'master_'
      services_hadoop[:master_endpoints].each do |name, r|
        name = r[:name]
        res[prefix+name+'_host'] = r[:host]
        res[prefix+name+'_port'] = r[:port]
        res[prefix+name+'_protocol'] = r[:protocol]

        res[prefix+name+'_port_out'] = r[:port_out]

      end

      # node
      prefix = 'node_'
      services_hadoop[:node_endpoints].each do |name, r|
        name = r[:name]
        res[prefix+name+'_host'] = r[:host]
        # ip
        res_ip = Gexcore::DnsService.get_ip_by_domain(r[:host])
        if res_ip.success?
          res[prefix+name+'_ip'] = res_ip.data[:ip]
        end

        res[prefix+name+'_port'] = r[:port]
        res[prefix+name+'_protocol'] = r[:protocol]

        res[prefix+name+'_port_out'] = r[:port_out]

      end

      Response.res_data(res)
    end


    ####

    def self.get_node_properties_install_by_user(user, node_uid)
      # check input
      return Response.res_error_badinput("", "Node not set") if node_uid.blank?

      # node
      node = Node.get_by_uid node_uid
      return Response.res_error_badinput("", "Node not found") if node_uid.blank?

      # check permissions
      if !(user.can? :view_node_info, node)
        return Response.res_error_forbidden("view_node_error", 'No permissions to view this node')
      end


      # work
      return get_node_properties_install(node)
    end


    def self.get_node_properties_install_by_agent(agent_node_id, node_uid)
      # check input
      return Response.res_error_badinput("", "Node not set") if node_uid.blank?

      node = Node.get_by_uid node_uid
      return Response.res_error("", "Node not found", "node state - node not found", 404) if node.nil?

      # check permissions
      if agent_node_id!=node.id
        return Response.res_error_forbidden("view_node_error", 'No permissions to view this node')
      end


      # work
      return get_node_properties_install(node)
    end


    def self.get_node_properties_install(node)
      s = Gexcore::Settings

      #
      hadoop_app = node.cluster.hadoop_app
      container_master = Gexcore::AppHadoop::App.get_container_master(hadoop_app)
      hadoop_master_ip = container_master.get_public_ip

      #
      data = {
          node_name: node.name,
          node_id: node.id,
          node_uid: node.uid,
          node_number: node.node_number,
          cluster_id: node.cluster_id,
          cluster_uid: node.cluster.uid,
          cluster_name: node.cluster.name,
          hadoop_type: node.cluster.hadoop_type.name,


          sensu_name: node.prop_sensu_name,
          sensu_node_id: node.prop_sensu_id,

          sensu_rmquser: s.rabbit_sensu_username,
          sensu_rmqpwd: s.rabbit_sensu_password,
          sensu_rmqhost: s.rabbit_url,

          hadoop_master_ipv4: hadoop_master_ip,

          openvpn_port: node.port,
          openvpn_ip_address: s.openvpn_host,

          vpn_client_ip: Gexcore::ClusterInfoService.get_node_property_vpn(node, 'client_ip'),
          vpn_server_ip: Gexcore::ClusterInfoService.get_node_property_vpn(node, 'server_ip'),
          vpn_server_port: Gexcore::ClusterInfoService.get_node_property_vpn(node, 'port'),

          api_ip: s.api_ip,
          dns_ip: s.dns_ip,


      }

      # enterprise options
      data.merge!(node.options_hash_enterprise)


      Response.res_data(data)
    end

    #### find
    def self.get_node_by_name(cluster, name)
      Node.where(cluster_id: cluster.id, name: name).first
    end

    #### nodes

    def self.create_node_by_user(instance_uid, user, cluster, sysinfo, extra_fields={})
      res = Response.new
      res.sysdata[:user_id] = user.id

      # user
      if user.is_a? Integer
        user = User.find(user)
      end
      return res.set_error('', 'User not found') if user.nil?

      # cluster
      return res.set_error_forbidden('', 'Select a cluster first', '') if cluster.nil?

      res.sysdata[:cluster_id] = cluster.id

      # check permissions
      if !(user.can? :manage, cluster)
        return res.set_error_forbidden('', 'You have no permissions to add node to this cluster.', '')
      end

      #
      return create_node(instance_uid, cluster, sysinfo, extra_fields)
    end

    def self.create_node(instance_uid, cluster, sysinfo, extra_fields={})
      res = Response.new
      res.sysdata[:cluster_id] = cluster.id

      gex_logger.debug("node_creating", "Creating node", {cluster_id: cluster.id, options: extra_fields})

      # host_type
      host_type = NodeHostType.get_by_id(extra_fields[:host_type_id]) || NodeHostType.get_by_name_with_default(extra_fields[:host_type_name])

      # instance
      instance = Instance.get_by_uid(instance_uid) if !instance_uid.nil? && !instance_uid.blank?
      #return res.set_error_forbidden('', 'Instance not found.', '') if instance.nil?
      if instance
        instance_id = instance.id
      else
        instance_id = nil
      end



      ### STEP 1. create node in DB

      node = nil
      res_create = false

      begin
        # create node - transaction
        ActiveRecord::Base.transaction do
          uid = Gexcore::Nodes::Service.generate_uid
          node_number = cluster.last_node_number+1
          #node_ip = Gexcore::IpsService.ipv6_for_node(cluster.id, node_number)
          node_ip = nil

          # name
          name = extra_fields[:custom_name] ? extra_fields[:custom_name] : Gexcore::Nodes::Service.get_name

          use_name(name)

          # hadoop app
          hadoop_app_id = nil
          if extra_fields[:hadoop_app]
            hadoop_app_id = cluster.hadoop_app_id
          end


          # add node to db
          node = Node.new(
              uid: uid,
              name: name,
              cluster: cluster,
              node_number: node_number,
              host_type_id: host_type.id,
              ip: node_ip,
              instance_id: instance_id,
              system_info: sysinfo,
              hadoop_app_id: hadoop_app_id,
              options: extra_fields[:options].to_json
          )
          node.save!

          #return res.set_error('', 'Cannot save data', "cannot save to table nodes") if !res_node

          # update node - set fields depending on id
          #node.name = extra_fields[:custom_name] ? extra_fields[:custom_name] : Gexcore::Nodes::Service.generate_unique_name(node.id)
          node.port = Gexcore::IpsService.port_for_node(node.id, node.node_number)
          node.agent_token = Gexcore::TokenGenerator.generate_node_agent_token
          node.save!

          # add sidekiq job
          #res_event = node.begin_install!
          node.after_begin_install

          #
          res.data[:node_id] = node.id

          # update instance last_node_id
          if instance
            instance.last_node_id = node.id
            instance.save!
          end


          # update cluster last node
          cluster.last_node_number +=1
          cluster.save!

          # create rabbitmq user
          res_rabbitmq = Gexcore::Nodes::Control.rabbitmq_create_user_for_node(node)
          #return res.set_error("", "Cannot provision master node", "Cannot provision: RabbitMQ error") if res_rabbitmq.error?
          raise 'Cannot install node' if res_rabbitmq.error?

          #
          res_create = true
        end

        if !res_create
          raise 'Error creating node'
        end


      rescue Response => e_response
        res_create = false

        gex_logger.info('node_create_error_exception', 'Cannot create node: exception', {cluster_id: cluster.id})
        res.set_error_exception("Cannot create node", e_response)
      rescue => e
        res_create = false
        gex_logger.exception("Cannot create node", e, {cluster_id: cluster.id})
        res.set_error_exception("Cannot create node", e)
      end

      if !res_create
        gex_logger.error('node_create_error', 'Cannot create node', {cluster_id: cluster.id})
        return res
      end

      #
      res.sysdata[:node_id] = node.id
      res.sysdata[:node_name] = node.name

      gex_logger.info("node_created", "Node created", {node_id: node.id})


      ### install

      gex_logger.debug("node_master_installing", "Installing on master", {node_id: node.id})

      res_install = false
      begin

        ### app hadoop
        if node.hadoop_app
          hadoop_type_name = cluster.hadoop_type.name
          app_name = "hadoop_#{hadoop_type_name}"
          app = ClusterApplication.get_by_name_and_cluster(app_name, cluster)

          # start install app
          res_app_install = Gexcore::AppHadoop::App.install_on_slave_node(app, node)
          if res_app_install.error?
            #gex_logger.log_response_base(res_app_install, 'error')
            raise 'Cannot install Hadoop on master'
          end
        end


        ### provision

        # add tasks for install job
        tasks = ['master', 'client']
        if node.node_type_name==ClusterType::AWS
          tasks << 'aws_instance'
        end

        tasks.each do |task|
          node.add_job_task('install', task)
        end

        node.start_job_task('install', 'master')
        if node.node_type_name==ClusterType::AWS
          # async
          NodeInstallAwsWorker.perform_async(node.id, get_env)
        else
          # sync
          res_provision = Gexcore::Nodes::Provision.provision_master_create_node(node.id)
          #return res.set_error("", "Cannot provision master node", "Cannot provision master node") if res_provision.error?
          if res_provision.error?
            raise "Cannot provision master node"
          end
        end

        # OK
        res_install = true
      rescue Response => e_response
        res_install = false

        gex_logger.error('node_master_install_error_exception', 'Cannot install Hadoop: exception', {node_id: node.id})
        res.set_error_exception("Cannot create node", e_response)
      rescue => e
        res_install = false

        gex_logger.exception("Cannot install Hadoop", e, {node_id: node.id})
        res.set_error_exception("Cannot install Hadoop", e)
      end


      ### result

      if !res_install
        node.set_install_error!

        gex_logger.error('node_master_install_error', 'Cannot install Hadoop on master', {node_id: node.id})
        return res
      end


      # OK
      gex_logger.debug("node_master_installed", "Node installed on master", {node_id: node.id})

      res.set_data({node_id: node.id})

      res
    end


    ### add nodes to cluster

    def self.add_nodes_to_cluster_by_user(user, cluster_uid, n_nodes, opts={})
      gex_logger.debug("nodes_adding", "Add nodes to cluster by user", {cluster_uid: cluster_uid, n: n_nodes})


      res = Response.new
      res.sysdata[:user_id] = user.id
      res.set_data

      # user
      if user.is_a? Integer
        user = User.find(user)
      end
      return res.set_error('', 'User not found') if user.nil?

      # cluster
      cluster = Cluster.get_by_uid(cluster_uid)
      return res.set_error_forbidden('', 'Select a cluster first', '') if cluster.nil?

      res.sysdata[:cluster_id] = cluster.id

      # check permissions
      if !(user.can? :manage, cluster)
        return res.set_error_forbidden('', 'You have no permissions to add node to this cluster.', '')
      end

      #
      user_token = Gexcore::AuthService.jwt_generate user
      opts[:user_token] = user_token

      res.data[:nodes] = []

      1.upto(n_nodes) do |ind|
        res_node = add_node_to_cluster(cluster, opts)

        if res_node.error?
          #gex_logger.critical("node_create_error", "Cannot create node", {cluster_id: cluster.id})
          res.set_error('node_create_error', 'Cannot create node', "Cannot create node aws")
          gex_logger.log_response_base(res, "critical")
          break
        end

        # ok - node added
        node_id = res_node.data[:node_id]
        node = Node.get_by_id(node_id)
        res.data[:nodes] << node.to_hash_created

      end

      res
    end

    def self.add_node_to_cluster(cluster, opts={})
      gex_logger.debug("node_adding", "Adding node to cluster", {cluster_id: cluster.id, opts: opts})

      if cluster.cluster_type_name==ClusterType::AWS
        return Gexcore::Nodes::Aws::Service.add_node_to_cluster(cluster, opts)
      end

      Gexcore::Response.res_error("node_create_error", 'Add node is not supported for this cluster', 'add_node_to_cluster - error')
    end


    ### setup

    def self.do_after_install_job_changed(node, task_name, task_state)
      # skip if job started
      if task_state==Node::JOB_STATE_STARTED
        return true
      end

      # if already failed => do nothing
      return true if node.install_error?
      return false if !node.installing?


      # some tasks with errors => set error
      if node.job_errors?('install')
        node.set_install_error!
        return true
      end


      # all finished
      if node.job_finished?('install')
        node.finish_install!
        return true
      end

      # job is not finished, more tasks to do => wait more
      true
    end

    def self.do_after_installed(node)
      # status for containers
      containers = node.containers.all
      containers.each do |container|
        res_container_status = container.finish_install!
      end

      # start node
      res_start = Gexcore::Nodes::Control.start_node(node)
      res_start
    end


    def self.do_after_install_error(node)
      # status for containers
      containers = node.containers.all
      containers.each do |container|
        res_container_status = container.set_install_error!
        container.save
      end

      # uninstall if needed
      if node.node_type_name==ClusterType::ONPREM
        # do nothing

      elsif node.node_type_name==ClusterType::AWS
        return Gexcore::Nodes::Service.uninstall_node(node)
      end

      Response.res_data
    end


    ###

    def self.do_after_begin_start(node)
      # fix status
      NodesFixStatusWorker.perform_in(30.minutes, node.id, 'starting', 'start_error')

      # status for containers
      containers = node.containers.all
      containers.each do |container|
        res_container_status = container.begin_start!
      end
    end



    def self.do_after_started(node)
      # status for containers
      containers = node.containers.all
      containers.each do |container|
        res_container_status = container.finish_start!
      end

      # start node
      #res_start = Gexcore::Nodes::Control.start_node(node)
      #res_start
    end


    def self.do_after_start_error(node)

      # status for containers
      containers = node.containers.all
      containers.each do |container|
        res_container_status = container.set_start_error!
      end

    end




    ### stop

    def self.do_after_begin_stop(node)
      # fix status
      NodesFixStatusWorker.perform_in(30.minutes, node.id, 'stopping', 'stop_error')

      # status for containers
      containers = node.containers.all
      containers.each do |container|
        res_container_status = container.begin_stop!
      end
    end


    def self.do_after_stopped(node)
      # status for containers
      containers = node.containers.all
      containers.each do |container|
        res_container_status = container.finish_stop!
      end
    end

    def self.do_after_stop_error(node)
      # status for containers
      containers = node.containers.all
      containers.each do |container|
        res_container_status = container.set_stop_error!
      end

    end




    ### restart

    def self.do_after_begin_restart(node)
      # fix status
      NodesFixStatusWorker.perform_in(30.minutes, node.id, 'restarting', 'restart_error')

      # status for containers
      containers = node.containers.all
      containers.each do |container|
        res_container_status = container.begin_restart!
      end

    end


    def self.do_after_restarted(node)
      # status for containers
      containers = node.containers.all
      containers.each do |container|
        res_container_status = container.finish_restart!
      end

    end


    def self.do_after_restart_error(node)
      # status for containers
      containers = node.containers.all
      containers.each do |container|
        res_container_status = container.set_restart_error!
      end

    end


    ### uninstall

    def self.do_after_uninstall_job_changed(node, task_name, task_state)
      gex_logger.debug("node_job_state", "do_after_uninstall_job_changed. task #{task_name}, state #{task_state}", {node_id: node.id, task: task_name, state: task_state})

      # skip if job started
      return true if task_state==Node::JOB_STATE_STARTED

      # if already failed => do nothing
      return true if node.uninstall_error?
      return false if !node.uninstalling?

      #gex_logger.debug("node_job_state", "do_after_uninstall_job_changed - check", {node_id: node.id, task: task_name, state: task_state})

      # some tasks with errors => set error
      if node.job_errors?('uninstall')
        node.set_uninstall_error!
        return true
      end


      # all finished
      gex_logger.debug("node_job_state", "do_after_uninstall_job_changed - check finished", {node_id: node.id, task: task_name, state: task_state})

      if node.job_finished?('uninstall')
        gex_logger.debug("node_job_state", "do_after_uninstall_job_changed - FINISHED!", {node_id: node.id, task: task_name, state: task_state})

        node.finish_uninstall!
        return true
      end

      gex_logger.debug("node_job_state", "do_after_uninstall_job_changed - nothing to do", {node_id: node.id, task: task_name, state: task_state})

      # job is not finished, more tasks to do => wait more
      true
    end


    def self.do_after_begin_uninstall(node)
      # fix hanged job
      NodesFixStatusWorker.perform_in(1.hour, node.id, 'uninstalling', 'uninstall_error')

      # status for containers
      containers = node.containers.all
      containers.each do |container|
        res_container_status = container.begin_uninstall!
      end


      true
    end

    def self.do_after_uninstalled(node)
      # remove
      return remove_node(node)
    end


    ### uninstall

    def self.uninstall_node_by_user(user, node_uid)
      res = Response.new
      res.sysdata[:user_id] = user.id

      #
      if node_uid.is_a? Node
        node = node_uid
      else
        node = Node.get_by_uid node_uid
      end

      return res.set_error_badinput('', 'Node not found', '') if node.nil?

      #
      res.sysdata[:node_id] = node.id

      # check permissions
      if !(user.can? :manage, node.cluster)
        return res.set_error_forbidden('', 'You have no permissions to uninstall node', '')
      end


      # do the work
      return uninstall_node(node)
    end


    def self.uninstall_node(node)
      res = Response.new
      res.sysdata[:node_id] = node.id

      # start
      res_status = node.begin_uninstall!
      if !res_status
        return res.set_error('uninstall_node_error', 'Cannot change node status', '')
      end

      # provision
      # start uninstall job
      tasks = ['master', 'client']
      tasks.each do |task|
        node.add_job_task('uninstall', task)
      end

      node.start_job_task('uninstall', 'master')
      node.start_job_task('uninstall', 'client')


      # provision - remove_node
      if node.node_type_name==ClusterType::AWS
        res_task = NodeUninstallAwsWorker.perform_async(node.id, get_env)
      elsif node.node_type_name==ClusterType::ONPREM
        res_task = NodeUninstallProvisionMasterWorker.perform_async(node.id, get_env)
      end


      # error
      #return res.set_error('uninstall_node_error', 'Cannot uninstall this node', '')

      res
    end


    ### remove

    def self.remove_node_by_user(user, node_uid)
      res = Response.new
      res.sysdata[:user_id] = user.id

      #
      if node_uid.is_a? Node
        node = node_uid
      else
        node = Node.get_by_uid node_uid
      end

      return res.set_error_badinput('', 'Node not found', '') if node.nil?

      #
      res.sysdata[:node_id] = node.id

      # check permissions
      if !(user.can? :manage, node.cluster)
        return res.set_error_forbidden('', 'You have no permissions to remove node', '')
      end


      # do the work
      res = remove_node(node)

      return res
    end


    def self.remove_node(node)
      res = Response.new
      res.sysdata[:node_id] = node.id

      # start removing
      res_status = node.begin_remove!
      return res.set_error('remove_node_error', 'Cannot change node status', '') if !res_status


      # do the work
      begin
        # send command to node agent
        #res_command = Gexcore::Nodes::Control.send_command(node, 'reconnect')

        #if res_command.error?
        #  res.set_error("", 'Cannot connect to node', 'cannot send command reconnect to the node')
        #  raise 'error'
        #end


        # delete apps
        res_apps = remove_all_apps_for_node(node)

        # delete containers
        res_containers = remove_all_containers_for_node(node)

        if res_containers.error?
          res.set_error("remove_node_error", 'Cannot delete containers', 'cannot delete Containers in DB')
          raise 'error'
        end


        # delete RabbitMQ data
        res_rabbit = Gexcore::Nodes::Control.rabbitmq_delete_all_for_node(node)

        if res_rabbit.error?
          res.set_error("remove_node_error", 'Cannot delete node', 'cannot delete RabbitMQ data')
          raise 'error'
        end

        # ok
        res.set_data
      rescue => e
        if res.success?
          res.set_error_exception('Cannot remove node', e)
        end
      end

      if res.error?
        node.set_remove_error!
        return res
      end

      # status removed
      res_status = node.finish_remove!
      return res.set_error("node_change_state_error",
                           'Cannot change node state', "error changing state: event=#{removed} ") if !res_status

      #
      res.set_data
    end


    def self.remove_node_provision_master_enqueue(node)
      gex_logger.debug("debug_provision", "Enqueue provision master - remove node", {node_id: node.id})


      return Response.res_data
    end


    ### nodes list
=begin
    def self.list_nodes(cluster_id, mode='info')
      #
      rows = get_nodes_for_cluster cluster_id

      # return data in hashes
      data = []

      rows.each do |row|
        node_hash = row.to_hash

        # add state
        if mode=='state'
          # state
          state = Gexcore::Monitoring::NodesMonitoring.get_node_state_keepalive row
          node_hash[:state] = state[:value]
        end

        #node_hash.delete(:cluster)

        data << node_hash
      end


      return Gexcore::Response.res_data({nodes: data})
    end
=end

    def self.list_nodes_to_json(rows, mode='info', checks=nil)
      # return data in hashes
      data = []

      rows.each_with_index do |row, i|
        node_hash = row.to_hash

        # add state
        if mode=='state' && checks && checks.count>0
          # state
          #state = node_states[i] #Gexcore::Monitoring::NodesMonitoring.get_node_state_keepalive row
          #node_hash[:state] = state[:value]

          #node_hash[:state] = node_states[i]
          node_hash[:checks] = checks[row.uid]
        end

        #node_hash.delete(:cluster)

        data << node_hash
      end


      return Gexcore::Response.res_data({nodes: data})
    end


    def self.get_nodes_for_cluster_by_user(user, cluster)
      # check input

      if !cluster
        return nil
      end

      #if !cluster
      #  return Gexcore::Response.res_error_badinput('', 'wrong cluster id provided', "wrong cluster id provided")
      #end

      # TODO: check permissions


      # work
      items = get_nodes_for_cluster(cluster.id)

      items
    end


    def self.get_nodes_for_cluster(cluster_id)
      Node.w_not_deleted.includes(:cluster, :host_type).where(cluster_id: cluster_id).order("id desc").limit(1000)
    end


    ### containers
    def self.create_containers!(node)
      containers_names = ServiceContainer.all_names

      containers_names.each do |container_name|
        log_data = {node_id: node.id, container_name: container_name}

        # add to DB
        ip = Gexcore::ServiceNodeContainer.allocate_ip(node)

        res_container = ClusterContainer.add_for_node(container_name, node, ip)

        if !res_container
          gex_logger.error('', 'Cannot create container for node', log_data)
          raise 'Cannot create container for node'
        end
      end

      return true
    end


    ### apps

    def self.remove_all_apps_for_node(node)

      begin
        # find apps in the node
        containers = node.containers.w_not_deleted.all
        ids_apps = containers.where.not("(name LIKE 'hadoop%' || name LIKE 'hue%')").all.map { |r| r.application_id }.uniq

        ids_apps.each do |app_id|
          app = ClusterApplication.get_by_id(app_id)
          Gexcore::Applications::Service.remove_application(app)
        end

      rescue => e
        gex_logger.exception "cannot delete apps for node", e, {node_id: node.id}

        res = Response.res_error_exception('Error', e)
        return res
      end

      # OK
      Response.res_data
    end

    ### containers

    def self.remove_all_containers_for_node(node)

      begin
        node.containers.w_not_deleted.all.each do |container|
          Gexcore::Containers::Container.remove_container(container)
        end
          #ClusterContainer.where(node_id: node.id).delete_all
      rescue => e
        gex_logger.exception "cannot delete containers for node", e, {node_id: node.id}

        res = Response.res_error_exception('Error', e)
        return res
      end

      # OK
      gex_logger.debug "debug_delete_node_containers", "containers removed from DB", {node_id: node.id}
      Response.res_data
    end


    ###
    def self.update_node(node, data)
      res = Response.new

      if node.is_a? String
        node = Node.get_by_uid(node)
      end

      if node.nil?
        return res.res_error("", "Node not found", "node nil", 404)
      end

      # check removed
      if node.removed?
        return res.res_error("", "Node not found", "Node removed", 404)
      end

      #
      res.sysdata[:node_id] = node.id

      # work
      if data[:instance_uid]
        node.instance = Instance.get_by_uid(data[:instance_uid])
      end
      if data[:host_type]
        node.host_type = NodeHostType.get_by_name(data[:host_type])
      end
      if data[:options]
        node.update_options(data[:options])
      end

      res_db = node.save

      if !res_db
        return res.res_error("node_update_error", "Cannot update node", "Error in db")
      end

      #
      res.set_data
    end


    ### node state

=begin
    def self.get_nodes_for_cluster_with_checks_by_user(user, cluster, mode)
      # check input
      if !cluster
        return Gexcore::Response.res_error_badinput('', 'wrong cluster id provided', "wrong cluster id provided")
      end

      # check permissions


      # list of nodes
      items = get_nodes_for_cluster(cluster)

      # checks
      node_states =[]
      items.each do |item|
        state_res = Gexcore::Nodes::Service.get_node_state_by_user(user, item)
        if state_res.success?
          node_states.push(state_res.data[:node][:state])
        end
      end


      # pack result
      res = Gexcore::Nodes::Service.list_nodes_to_json(items, mode, node_states)

      res

      items
    end
=end


    def self.get_node_state_by_user(user, node)

      if node.is_a? String
        node_uid = node
        node = Node.get_by_uid node_uid
      end

      return Response.res_error("", "Node not found", "node state - node not found", 404) if node.nil?

      # check permissions
      if !(user.can? :view_node_info, node)
        return Response.res_error_forbidden("view_node_error", 'No permissions to view this node')
      end

      # work
      checks = Gexcore::Monitoring::NodesMonitoring.get_checks_for_node(node)

      Response.res_data({checks: checks})
    end


    def self.get_node_state_by_agent(agent_node_id, node_uid)
      # check input
      return Response.res_error_badinput("", "Node not set") if node_uid.blank?

      node = Node.get_by_uid node_uid
      return Response.res_error("", "Node not found", "node state - node not found", 404) if node.nil?

      # check permissions
      if agent_node_id!=node.id
        return Response.res_error_forbidden("view_node_error", 'No permissions to view this node')
      end


      # work
      checks = Gexcore::Monitoring::NodesMonitoring.get_checks_for_node(node)

      Response.res_data({checks: checks})
    end



    ### fix node status
    def self.fix_nodes_status
      raise 'not implemented'

      rows = Node.w_not_deleted.w_statuses_working.all

      row.each do |node|

      end

    end

    def self.fix_node_status(node_or_id, old_status, new_status)
      res = Gexcore::Response.new

      # input
      if node_or_id.is_a? Node
        node = node_or_id
      else
        node = Node.get_by_id(node_or_id)
      end

      if node.nil?
        return res.set_error('node_status_change', 'Node not found')
      end

      #
      res.sysdata[:node_id] = node.id

      if node.status.to_s == old_status
        #new_status = Node::STATUSES_WORKING_MAPPING_ERRORS[node.status.to_sym]

        res_event = node.send(:"set_#{new_status.to_s}!")

        if !res_event
          return Response.res_error("node_change_status_error", 'Cannot change node status', "error changing status: status=#{new_status} ")
        end

        return res
      end

      return res.set_data
    end

    ####
    def self.generate_uid
      d = Date.today
      d.strftime('%y%j') + Gexcore::Common.random_string_digits(11)
    end


    ### files for vagrant

    def self.dir_vagrant(cluster_id, node_number)
      "clusters/#{cluster_id}/vagrant/#{node_number}"
    end


    ### consul

    # format = hash | kv
    def self.consul_build_node_data(node, format='hash')

      #
      container_hadoop_master = node.cluster.get_master_container('hadoop')
      #hadoop_master_ipv4 = Gexcore::Containers::Service.get_public_ip_of_container(container_hadoop_master)
      hadoop_master_ipv4 = container_hadoop_master.gex_ip

      args = {
          'cluster_id'=>node.cluster_id,
          'uid'=>node.uid,
          'id'=>node.id,
          'name'=>node.name,
          'hadoop_app_id'=>node.hadoop_app_id,
          'node_number'=>node.node_number,
          'node_type'=>node.node_type_name,
          'host_type'=>node.host_type_name,
          'hadoop_type'=>node.cluster.hadoop_type.name,
          'hadoop_master_ipv4'=>hadoop_master_ipv4,

          'node_port'=>node.port,
          'node_ip6_address'=>node.ip,

          'agent_token' => node.agent_token

      }

      # interface
      v_interface = (node.options_hash['selected_interface']['name'] rescue '') || ''
      args['interface'] = Node.encode_option(v_interface)

      args['is_wifi'] = (node.options_hash['selected_interface']['isWifi'] rescue false)

      #args = %Q{_cluster_id=#{node.cluster_id} _cluster_uid=#{node.cluster.uid} _cluster_name=#{node.cluster.domainname} _node_uid=#{node.uid} _node_id=#{node.node_number} _hadoop_master_ipv4=#{hadoop_master_ipv4} _node_name=#{node.name} _node_port=#{node.port} _node_ip6_address=#{node.ip}  }

      # for aws
      if node.node_type_name==ClusterType::AWS
        args_aws = build_params_node_data_fields_aws(node)
        args.merge!(args_aws)
      end



      # advanced options
      args_advanced = build_params_node_data_fields_advanced(node)
      args.merge!(args_advanced)


      # proxy/webproxy for services for hadoop
      services = node.services.all
      services.each do |r|
        #next unless ['ssh', 'http'].include? r.protocol
        next unless r.need_proxy?

        args["port_#{r.name}"] = r.port_out
      end

      #
      return Gexcore::Provision::Service.params_hash_format(args, format)
    end

    def self.build_params_node_data_fields_advanced(node)
      cluster = node.cluster
      return {} if cluster.options_hash.nil?

      res = {}

      res['proxy_ip'] = cluster.get_option('proxyIP')
      res['static_ips'] = cluster.option_static_ips?
      res['gateway_ip'] = cluster.get_option('gatewayIP')
      res['network_mask'] = cluster.get_option('networkMask')

      # containers ips
      res['container_ips'] = {}
      node.containers.each do |container|
        res['container_ips'][container.basename] = container.get_public_ip
      end

      res
    end


    def self.build_params_node_data_fields_aws(node, opts={}, format="hash")
      #cluster = node.cluster

      #
      args = {
          'instance_type'=> node.options_hash['aws_instance_type'],
          'volume_size'=> node.options_hash['volume_size'],

      }

      args.compact!

      #
      return Gexcore::Provision::Service.params_hash_format(args, format)
    end


    def self.consul_update_node_data(node)
      data = consul_build_node_data(node, 'hash')
      Gexcore::Consul::Service.update_node_data(node, data)
    end

    def self.consul_update_web_services(node)
      web_services = []

      node_web_services = node.services.w_http
      node_web_services.each do |service|
        web_services << service.to_hash_webproxy
      end

      gex_logger.debug('debug_provision',"run provision - consul_update_web_services", {node_id: node.id, web_services: web_services.to_json})

      Gexcore::Consul::Service.update_node_data(node, {web_services: web_services})
    end


    ### name generator

    def self.filename_stars
      return 'data/stars.json'
    end

    def self.filename_adjectives
      return 'data/adjectives.json'
    end


    def self.generate_name(id)
      generator = Gexcore::NameGenerator.new(filename_stars, filename_adjectives)

      return generator.generate_name(id)
    end


    def self.generate_unique_name(id)
      name = generate_name(id)
      i = 1

      until Node.w_not_deleted.where(name: name).empty? do
        postfix = i.humanize.gsub(' ', '-').gsub(',', '')
        name = name + '-' + postfix
      end
      name
    end


    def self.get_key_node_names_full
      config.redis_prefix+':nodes:names_full'
    end

    def self.get_key_node_names
      config.redis_prefix+':nodes:names'
    end

    def self.get_key_node_names_lock
      config.redis_prefix+':nodes:names_lock'
    end


    def self.get_name
      names_set = get_key_node_names
      name = $redis.spop names_set

      if name.nil?
        Gexcore::Nodes::Service.rebuild_names
        name = $redis.spop names_set
      end

      name
    end

    # name is used
    def self.use_name(name)

      return true unless is_locked_rebuilding

      Timeout.timeout 15 do
        if is_locked_rebuilding
          raise 'Node names service are unavailable'
        else
          return true
        end
      end

    end


    def self.is_name_available(name)
      $redis.sismember get_key_node_names, name
    end


    def self.is_locked_rebuilding
      $redis.get(get_key_node_names_lock).to_b
    end


    def self.set_lock_rebuilding
      $redis.set(get_key_node_names_lock, true)
    end


    def self.release_lock_rebuilding
      $redis.set(get_key_node_names_lock, false)
    end


    def self.rebuild_names

      names_set_full = get_key_node_names_full
      names_set = get_key_node_names

      # first time
      if !$redis.exists(names_set_full) || $redis.scard(names_set_full) == 0

        generator = Gexcore::NameGenerator.new(filename_stars, filename_adjectives)
        nouns = generator.get_nouns
        adjectives = generator.get_adjectives

        nouns.each do |noun|
          adjectives.each do |adj|
            name = adj+'-'+noun
            $redis.sadd names_set_full, name
          end
          $redis.sadd names_set_full, noun
        end
      end


      set_lock_rebuilding
      begin

        node_names = Node.w_not_deleted.pluck(:name)

        $redis.del names_set
        $redis.sunionstore names_set, names_set_full
        $redis.srem names_set, node_names

        day = 24*60*60
        $redis.expire names_set_full, day*30
        $redis.expire names_set, day*7
      rescue => e
        gex_logger.exception("Cannot rebuild node names", e)
      end
      release_lock_rebuilding
    end


  end
end
