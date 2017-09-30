module Gexcore::Clusters
  class Service < Gexcore::BaseService


    ### log
    def self.log_status_change(cluster)
      gex_logger.info("cluster_status_changed", "Cluster state changed from #{cluster.aasm.current_state} to #{cluster.aasm.to_state}",
                      {cluster_id: cluster.id, from: cluster.aasm.current_state, to: cluster.aasm.to_state, event: cluster.aasm.current_event}
      )
    end

    def self.log_installed(cluster)
      gex_logger.info('cluster_installed', "Cluster was installed: #{cluster.name}", {cluster_id: cluster.id})
    end
    def self.log_install_error(cluster)
      gex_logger.info('cluster_install_error', "Error installing cluster: #{cluster.name}", {cluster_id: cluster.id})
    end

    ### create cluster

    def self.create_cluster_by_user(user, sysdata={}, options={})
      # check permissions
      if !(user.can? :cluster_create, nil)
        return Response.res_error_forbidden('','No permissions to create cluster', 'No permissions to create cluster')
      end


      res = create_cluster(user, sysdata, options)

      # log
      #gex_logger.log_response(res, 'cluster_created', "Cluster created: :name", 'cluster_create_error')

      res
    end

    def self.create_cluster(user, sysdata={}, options={})
      res = Response.new

      logdata = []

      # validate data
      res_valid = validate_create_cluster_data(user, options)
      return res_valid if res_valid.error?


      begin
        team = user.team

        # log
        gex_logger.debug_response(res, 'cluster_create_started', {user_id: user.id})


        #
        app = nil
        cluster = nil
        res_create = false

        # hadoop type
        hadoop_type_name = options['hadoopType'] || options[:hadoop_type] || ClusterHadoopType::DEFAULT_NAME
        hadoop_type_id = ClusterHadoopType.get_id_by_name hadoop_type_name

        # cluster type
        cluster_type_name = options[:cluster_type] || ClusterType::DEFAULT_NAME
        cluster_type = ClusterType.get_by_name(cluster_type_name)

        #
        cluster_uid = Gexcore::TokenGenerator.generate_cluster_uid

        ActiveRecord::Base.transaction do
          cluster = Cluster.new(team: team, uid: cluster_uid, primary_admin: team.primary_admin,
                                hadoop_type_id: hadoop_type_id,
                                cluster_type: cluster_type,
                                options: options.to_json)

          res_cluster = cluster.save!


          # update domainname
          cluster.domainname = Gexcore::Clusters::Service.generate_name(cluster.id)
          cluster.name = cluster.domainname
          #cluster.team.main_cluster_id = cluster.id
          cluster.save!

          #
          res.sysdata[:cluster_id] = cluster.id
          res.sysdata[:cluster_name] = cluster.name


          # notify
          Gexcore::Log::Slack.cluster_created(cluster)


          # OLD. add user to superadmin
          #g = Group.group_superadmin
          #ug = UserGroup.new(cluster: cluster, user: user, group: g)
          #res_ug = ug.save!
          #return Response.res_error('', 'Cannot save data', 'cannot save to table users_groups') if !res_ug

          # update related data
          #user.main_cluster_id = cluster.id
          #user.save!

          # team
          #team.main_cluster_id = cluster.id
          #team.save!

          #
          res_create = true
        end


        if !res_create
          raise 'Error creating cluster'
        end

        # OK - cluster created
        res.set_data(
            {
                cluster: {id: cluster.uid, name: cluster.name, domainname: cluster.domainname }
            }
        )

        # log
        gex_logger.log_response(res, 'cluster_created', "Cluster was created: :cluster_name", 'cluster_create_error', {user_id: user.id} )

        #gex_logger.info('cluster_created', "Cluster created", {cluster_id: cluster.id} )


        ### provision - consul
        #res_consul = Gexcore::Clusters::Provision.create_consul(cluster)
        #raise 'Cannot provision cluster - error creating Consul' if res_consul.error?


        ### app hadoop
        app_name = "hadoop_#{hadoop_type_name}"
        res_app = Gexcore::AppHadoop::App.create_hadoop_application(app_name, cluster)

        raise 'Cannot create application Hadoop' if res_app.error?

        #app = ClusterApplication.get_by_id(res_app.data[:application_id])
        res.sysdata[:application_id] = res_app.data[:application_id]



        # OK


      rescue Response => e_response
        puts "ex. #{e_response}"

        gex_logger.error('cluster_create_error_exception', 'create_cluster EXCEPTION res', {user_id: user.id})

        res.set_error_exception("Cannot create cluster", e_response)
      rescue => e
        puts "ex2. #{e}"

        #gex_logger.error('cluster_create_error_exception', 'create_cluster EXCEPTION general', {user_id: user.id, e: e.message})
        gex_logger.exception('create_cluster EXCEPTION', e, {user_id: user.id})
        res.set_error_exception("Cannot create cluster", e)
      end

      #
      res
    end






    ###

    def self.build_cluster_options_from_user(user)
      res = {}
      res = user.registration_options_hash

      res
    end

    # check if cluster data is valid
    def self.validate_create_cluster_data(user, options)
      res = Response.new

      #
      cluster_type_name = options[:cluster_type] || ClusterType::DEFAULT_NAME
      cluster_type = ClusterType.get_by_name(cluster_type_name)

      if cluster_type.nil?
        return res.set_error("cluster_invalid", "Wrong cluster type", "cluster type not found")
      end


      # custom checks
      res_validate = nil
      if cluster_type.name==ClusterType::ONPREM
        res_validate = Gexcore::Clusters::Onprem::Service.validate_create_cluster_data(user, options)
      elsif cluster_type.name==ClusterType::AWS
        res_validate = Gexcore::Clusters::Aws::Service.validate_create_cluster_data(user, options)
      end

      #mtd = "validate_create_cluster_data_#{cluster_type.name}"
      #return send(mtd, user, options)
    end



    ### callbacks for install

    def self.do_after_installed(cluster)
      ## containers
      #containers = cluster.containers.all
      #containers.each do |container|
      #  container.set_active!
      #end

      cluster.activate!
    end


    ###

    def self.email_after_cluster_installed(cluster)
      UsersMailer.cluster_info_email(cluster.id).deliver_later
    end




    ### list

    # format = hash, object
    def self.get_clusters_in_team_by_user(user, team, format='hash')
      # check permissions
      if !(user.can? :view_clusters_in_team, team)
        return Response.res_error_forbidden("view_clusters_error", 'No permissions to view clusters')
      end

      #
      rows = list_clusters_in_team team.id
      #
      cluster_ids = rows.map(&:id)
      nodes_not_del_count = Node.w_not_deleted.where(:cluster_id => cluster_ids).group(:cluster_id).count
      nodes_joined_count = Node.w_joined.where(:cluster_id => cluster_ids).group(:cluster_id).count
      aws_regions = AwsRegion.all

      if format=='hash'
        #rows_hash = rows.map{|r| r.to_hash }
        rows_hash = Gexcore::Clusters::Service.to_hash_with_node_counters(rows, nodes_not_del_count, nodes_joined_count, aws_regions)
        data = {clusters: rows_hash}
      else
        data = rows
      end

      Response.res_data(data)
    end

    def self.to_hash_with_node_counters(rows, nodes_not_del_count, nodes_joined_count, aws_regions)
      rows.map do |t|

        settings = t.options_hash_public
        aws_region_title = settings['aws_region'] ? aws_regions.find{|region| region.name == settings['aws_region']}.title : nil rescue nil
        settings[:awsRegionTitle] = aws_region_title

        {
            id: t.uid,
            name: t.name,
            domainname: t.domainname,
            status: t.status,
            hadoopApplicationID: t.hadoop_app_uid,
            clusterType: t.cluster_type_name,
            numberOfNodes: nodes_not_del_count[t.id].nil? ? 0 : nodes_not_del_count[t.id],
            numberOfJoined: nodes_joined_count[t.id].nil? ? 0 : nodes_joined_count[t.id],
            team: {
                name: t.team.name
            },
            settings: settings
        }
      end
    end

    def self.list_clusters_in_team(team_id)
      Cluster.w_not_deleted.includes(:team, :hadoop_app, :hadoop_type, :cluster_type).where(:team_id => team_id).order("id DESC").all
    end


    ### delete cluster

    def self.delete_cluster_by_user(user, cluster_uid)
      # input
      return Response.res_error_badinput('cluster_delete_badinput','user not found', "bad user") if user.nil?

      #
      cluster = Cluster.get_by_uid cluster_uid
      if cluster.nil?
        return Response.res_error_badinput('cluster_delete_empty','Cluster not found', "Cluster uid not found: #{cluster_uid}")
      end

      # check permissions
      if !(user.can? :cluster_delete, cluster)
        return Response.res_error_forbidden('cluster_delete_denied','No permissions to create cluster', 'No permissions to create cluster')
      end


      # work - async
      ClusterDeleteWorker.perform_async(cluster.id, get_env)

      Response.res_data
    end

    def self.delete_cluster(cluster, sysdata={})
      res = Response.new

      if cluster.is_a? Integer
        cluster_id = cluster
        cluster = Cluster.get_by_id cluster_id
      end
      res.sysdata[:cluster_id] = cluster.id

      # checks
      if cluster.nodes.w_not_deleted.count > 0
        #raise 'Cannot delete cluster with nodes'
        return res.set_error('cluster_uninstall_error', 'Cannot delete cluster with nodes', '')
      end

      #
      res_status = cluster.begin_uninstall!
      return res.set_error('cluster_uninstall_error', 'Cannot change cluster status', '') if !res_status

      begin


        # delete apps
        res_apps = uninstall_all_apps_for_cluster(cluster)

        if res_apps.error?
          raise 'Cannot delete applications'
        end

        # ok
        res.set_data
      rescue => e
        gex_logger.error("cluster_uninstall_error", e.message, {cluster_id: cluster.id})
        res.set_error('cluster_uninstall_error', e.message)
      end


      if res.error?
        cluster.set_uninstall_error!
        return res
      end

      # status removed
      res_status = cluster.finish_uninstall!
      if !res_status
        return  res.set_error("cluster_uninstall_error", 'Cannot change cluster status')
      end


      #
      res.set_data
    end


    # delete cluster all
    def self.delete_cluster_all_by_user(user, cluster_uid)
      # input
      if user.nil?
        return Response.res_error_badinput('cluster_delete_badinput','user not found', "bad user")
      end

      #
      cluster = Cluster.get_by_uid cluster_uid
      if cluster.nil?
        return Response.res_error_badinput('cluster_delete_empty','Cluster not found', "Cluster uid not found: #{cluster_uid}")
      end

      # check permissions
      if !(user.can? :cluster_delete, cluster)
        return Response.res_error_forbidden('cluster_delete_denied','No permissions to create cluster', 'No permissions to create cluster')
      end

      res_status = cluster.begin_uninstall!
      return res.set_error('cluster_uninstall_error', 'Cannot change cluster status', '') if !res_status

      #node_ids = cluster.nodes.w_not_deleted.pluck(:id)

      nodes = cluster.nodes.w_not_deleted
      node_ids = []
      nodes.each do |node|
        node.begin_uninstall!
        node_ids << node.id
      end

      #res1 = Gexcore::Provision::Worker.run('ClusterUninstallAllWorker', {cluster_id: cluster.id, node_ids: node_ids, env: get_env})

      # work - async
      ClusterDeleteAllWorker.perform_async(cluster.id, node_ids, get_env)

      # debug
      #Gexcore::Clusters::Service.delete_cluster_all(cluster.id, node_ids, get_env)

      Response.res_data
    end


    def self.delete_cluster_all(cluster, node_ids, sysdata={})

      res = Response.new

      if cluster.is_a? Integer
        cluster_id = cluster
        cluster = Cluster.get_by_id cluster_id
      end
      res.sysdata[:cluster_id] = cluster.id


      res = Gexcore::Clusters::Provision.provision_master_uninstall_all_cluster(cluster, node_ids)

      if res.error?
        cluster.set_uninstall_error!
        return res
      end

      #
      res.set_data
    end








    def self.uninstall_all_apps_for_cluster(cluster)
      res = Response.new

      begin
        # all apps in cluster
        apps = cluster.applications.w_not_deleted.all
        apps.each do |app|
          gex_logger.debug("debug_app_uninstall", "starting app uninstall", {application_id: app.id})

          res_app = Gexcore::Applications::Service.uninstall_application(res, app)

          if res_app.error?
            gex_logger.log_response_base res_app, 'error'

            raise 'Cannot uninstall application in cluster'
          end

        end

      rescue => e
        #gex_logger.exception "cannot delete apps", e, {cluster_id: cluster.id}

        res = Response.res_error('cluster_uninstall_error', e.message)
        return res
      end

      # OK
      Response.res_data
    end




    def self.do_after_begin_uninstall(cluster)
      # run ansible remove_node.yml
      #remove_node_provision_master_enqueue(node)


      true
    end

    def self.do_after_uninstalled(cluster)
      # remove
      return remove_cluster(cluster)
    end



    ### remove cluster

    def self.remove_cluster(cluster)
      res = Response.new
      res.sysdata[:cluster_id] = cluster.id

      # start removing
      res_status = cluster.begin_remove!
      return res.set_error('cluster_remove_error', 'Cannot change cluster status', '') if !res_status


      # do the work
      begin
        # remove apps
        res_apps = remove_all_apps_for_cluster(cluster)

        # delete RabbitMQ data
        #res_rabbit = Gexcore::Nodes::Control.rabbitmq_delete_all_for_node(node)
        #if res_rabbit.error?
        #  res.set_error("remove_node_error", 'Cannot delete node', 'cannot delete RabbitMQ data')
        #  raise 'error'
        #end

        # ok
        res.set_data
      rescue => e
        if res.success?
          res.set_error_exception('Cannot remove cluster', e)
        end
      end

      if res.error?
        cluster.set_remove_error!
        return res
      end

      # status removed
      res_status = cluster.finish_remove!
      return  res.set_error("cluster_remove_error_status", 'Cannot change cluster status') if !res_status

      #
      res.set_data
    end


    def self.remove_all_apps_for_cluster(cluster)
      res = Response.new

      begin
        # all apps in cluster
        apps = cluster.applications.w_not_deleted.all
        apps.each do |app|
          res_app = Gexcore::Applications::Service.remove_application(app)

          if res_app.error?
            raise 'Cannot remove application'
          end

        end

      rescue => e
        res = Response.res_error('cluster_remove_error', e.message)
        return res
      end

      # OK
      Response.res_data
    end



    ### name generator

    def self.filename_galactics
      return File.join(Rails.root, 'data/galactics.json')
    end

    def self.filename_adjectives
      return File.join(Rails.root, 'data/adjectives.json')
    end


    def self.generate_name(id)
      generator = Gexcore::NameGenerator.new(filename_galactics, filename_adjectives)

      return generator.generate_name(id)
    end

    ### cluster info

    def self.get_cluster_info_by_user(user, cluster_uid)
      #
      cluster = Cluster.get_by_uid(cluster_uid)

      # cluster not exists
      return Response.res_error_badinput("", 'cluster not found', 'cluster not found') if cluster.nil?

      # check permissions
      if !(user.can? :view_cluster_info, cluster)
        return Response.res_error_forbidden("view_cluster_error", 'No permissions to view this cluster')
      end

      return get_cluster_info(cluster)
    end

    def self.get_cluster_info_by_agent(agent_node_id, cluster_uid)
      return Response.res_error_badinput("", "Cluster not set") if cluster_uid.blank?

      #
      cluster = Cluster.get_by_uid(cluster_uid)

      # cluster not exists
      return Response.res_error_badinput("", 'cluster not found', 'cluster not found') if cluster.nil?

      # check permissions
      node = Node.get_by_id(agent_node_id)
      if node.nil? || node.cluster_id!=cluster.id
        return Response.res_error_forbidden("cluster_view_error", 'No permissions to view this cluster')
      end

      # work
      return get_cluster_info(cluster)
    end

    def self.get_cluster_info(cluster)
      data = {
          cluster: cluster.to_hash_w_region,
          settings: cluster.options_hash_public
      }
      Response.res_data(data)
    end


    ### all info about cluster

    def self.get_cluster_info_all(cluster)
      res = {}

      res['cluster_id'] = cluster.id

      #
      services_hadoop = Gexcore::ClusterServices::Service.get_service_info_hadoop(cluster, nil)

      prefix = 'master_'
      services_hadoop[:master_endpoints].each do |name, r|
        name = r[:name]
        res[prefix+name+'_host'] = r[:host]
        res[prefix+name+'_port'] = r[:port]
        res[prefix+name+'_protocol'] = r[:protocol]

        res[prefix+name+'_port_out'] = r[:port_out]

      end

      Response.res_data(res)
    end


    ### consul


    def self.consul_update_cluster_data(cluster)
      data = consul_build_cluster_data(cluster, 'hash')

      Gexcore::Consul::Service.update_cluster_data(cluster, data)
    end



    # format = hash | kv
    def self.consul_build_cluster_data(cluster, format="hash")
      # params
      h = {}


      # basic params
      h.merge!({
                   id: cluster.id,
                   uid: cluster.uid,
                   cluster_type: cluster.cluster_type_name,
                   name: cluster.domainname,
                   id_hex: cluster.id.to_s(16),
                   hadoop_type: cluster.hadoop_type.name,
                   hadoop_app_id: cluster.hadoop_app_id
               })



      # hadoop - service ports
      hadoop_app = cluster.hadoop_app

      services = hadoop_app.services.w_master.all
      #s_ports = services.map{|r| "_port_#{r.name}=#{r.port_out}"}.join(' ')
      services.each{|r| h["port_#{r.name}"] = r.port_out}


      # more params from cluster.options_hash
      #return script_params if cluster.options_hash.nil?

      if cluster.cluster_type_name==ClusterType::AWS
        h.merge!(build_cluster_data_fields_aws(cluster))
      end

      # map fields
      mapping = {
          #'hadoopType' => '_hadoop_type',
          'proxyIP' => 'proxy_ip',
          'staticIPs' => 'static_ips',
          'gatewayIP' => 'gateway_ip',
          'networkMask' => 'network_mask',
          'networkIPRangeStart' => 'network_ip_range_start',
          'networkIPRangeEnd' => 'network_ip_range_end',
          'components' => 'components',
      }

      cluster.options_hash.each do |opt_name, v|
        param_name = mapping[opt_name.to_s]
        next if param_name.nil?

        h[param_name] = v
      end


      return Gexcore::Provision::Service.params_hash_format(h, format)
    end


    # params for aws
    def self.build_cluster_data_fields_aws(cluster, format="hash")
      res = {}

      res[:aws_region] = cluster.options_hash['aws_region']
      res[:aws_access_key_id] = cluster.options_hash['aws_key_id']
      res[:aws_secret_key] = cluster.options_hash['aws_secret_key']

      res.compact!

      res
    end


  end
end
