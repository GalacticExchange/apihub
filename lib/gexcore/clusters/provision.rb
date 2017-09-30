module Gexcore::Clusters
  class Provision < Gexcore::BaseService

    ### create cluster

    def self.provision_master_create_cluster(app, sysdata={})
      #
      res = Response.new
      res.set_sysdata sysdata

      #
      cluster = app.cluster
      res.sysdata[:application_id] = app.id
      res.sysdata[:cluster_id] = cluster.id

      # save to file
      #save_params_to_file(script_params, filename_properties_cluster(cluster))

      # save data to consul
      #Gexcore::Clusters::Service.consul_update_cluster_data(cluster)

      # provision
      cluster_data = Gexcore::Clusters::Service.consul_build_cluster_data(cluster, 'hash')

      script = Gexcore::Provision::Service.build_cmd_cap(
          'provision:create_cluster',
          "_cluster_id=#{cluster.id} _cluster_data='#{cluster_data.to_json}'"
      )

      res_provision = Gexcore::Provision::Service.run('create_cluster', script)

      # rollback
      if res_provision.error?
        if Rails.env.production?
          #cmd_rollback = Gexcore::Provision::Service.build_cmd_ansible "remove_cluster.yml", script_params
          #res_clean_ansible = Gexcore::Provision::Service.run("remove_cluster", cmd_rollback)

          res_provision_rollback = provision_master_remove_cluster(app, sysdata)
        end

        # error
        return res.set_error('cluster_install_error', 'Cannot create cluster', 'Cannot run provision script')
      end


      # OK
      #gex_logger.debug_response(res_ansible, 'ansible result', res.sysdata)
      gex_logger.debug('cluster_create_provision_result', "provision script result", res.sysdata.merge({res: res_provision}))


      res.set_data
    end


=begin

    def self.__old_build_params_hadoop_create_cluster_master(app, format="hash")
      cluster = app.cluster

      # run script
      params_hash = {}

      # service ports
      services = app.services.w_master.all
      #s_ports = services.map{|r| "_port_#{r.name}=#{r.port_out}"}.join(' ')
      services.each{|r| params_hash["_port_#{r.name}"] = r.port_out}

      # basic params
      #script_params = " _cluster_id=#{cluster.id} _cluster_name=#{cluster.domainname} _cluster_id_hex=#{cluster_id_hex} _hadoop_type=#{cluster.hadoop_type.name} #{s_ports} "
      params_hash.merge!({
                             gex_env: Gexcore::Settings.provision_env,
                             id: cluster.id,
                             uid: cluster.uid,
                             cluster_type: cluster.cluster_type_name,
                             name: cluster.domainname,
                             id_hex: cluster.id.to_s(16),
                             hadoop_type: cluster.hadoop_type.name
                         })

      # more params from cluster.options_hash
      #return script_params if cluster.options_hash.nil?

      if cluster.cluster_type_name==ClusterType::AWS
        params_hash.merge!(hadoop_create_cluster_master_params_aws(app,cluster))
      end

      #
      mapping = hadoop_create_cluster_master_params_mapping
      cluster.options_hash.each do |opt_name, v|
        param_name = mapping[opt_name.to_s]
        next if param_name.nil?
        #res << "#{param_name}=#{v}"
        params_hash[param_name] = v
      end

      return Gexcore::Provision::Service.params_hash_format(params_hash, format)
    end
=end







=begin
    def self.create_consul(cluster, sysdata={})
      #
      res = Response.new
      res.set_sysdata sysdata

      #
      res.sysdata[:cluster_id] = cluster.id

      gex_logger.debug('cluster_create_consul_start', "run provision create_consul - start", res.sysdata)

      # script params
      script_params = build_params_create_consul(cluster, "kv")

      script = %Q(#{script_params} cap #{Gexcore::Settings.gex_env} provision:create_consul)

      #
      res_provision = Gexcore::Provision::Service.run("create_consul", script)

      if res_provision.error?
        # return error
        res.set_error('provision_error', 'Cannot provision cluster', 'Cannot run provision script - consul')
        #gex_logger.error('debug_provision', 'Cannot provision cluster', {script: script, output: res_query.output})
        return res
      end


      #gex_logger.debug('provision_cluster_create_consul_result', "provision script result", res.sysdata.merge({res: res_ansible.success?}))

      res.set_data
    end



=end

    ###

    def self.fix_cluster_webproxy(cluster, sysdata={})
      script_yml = 'fix_cluster_webproxy.yml'

      app = cluster.hadoop_app

      #
      res = Response.new
      res.set_sysdata sysdata
      res.sysdata[:cluster_id] = cluster.id

      # script params
      script_params = build_params_hadoop_create_cluster_master(app)

      #cluster_id_hex = cluster.id.to_s(16)

      # ports
      #ports = Gexcore::ClusterServices::Service.get_service_ports(cluster)
      #s_ports = ports.map{|r| "_port_#{r.service.name}=#{r.port_out}"}.join(' ')

      #script_params = " _cluster_id=#{cluster.id} _cluster_name=#{cluster.domainname} _cluster_id_hex=#{cluster_id_hex} #{s_ports} "

      # enterprise options
      #script_params << create_cluster_ansible_script_params_enterprise(cluster)

      #
      cmd = Gexcore::Provision::Service.build_cmd_ansible script_yml, script_params
      res_provision = Gexcore::Provision::Service.run("fix_cluster_webproxy", cmd, res.sysdata)

      res_provision
    end

    ###
    # remove cluster
    # for remove_cluster.yml
    #

    def self.provision_master_remove_cluster(app, sysdata={})
      #
      res = Response.new
      res.set_sysdata sysdata

      #
      cluster = app.cluster
      res.sysdata[:cluster_id] = cluster.id

      gex_logger.debug('debug_provision', "run provision remove_cluster - start", res.sysdata)

      # run provision
      script = Gexcore::Provision::Service.build_cmd_cap(
          'provision:remove_cluster',
          "_cluster_id=#{cluster.id} _cluster_type=#{cluster.cluster_type_name}"
      )
      res_provision = Gexcore::Provision::Service.run('remove_cluster', script)


      # result
      gex_logger.debug_response(res_provision, 'provision result', res.sysdata)


      # rollback
      if res_provision.error?
        return res.set_error('cluster_remove_error', 'Cannot remove cluster', 'Cannot run ansible script')
      end

      res_provision
    end




    ###
    # uninstall cluster all
    # for delete_cluster_all.rb
    #

    def self.provision_master_uninstall_all_cluster(cluster, node_ids, sysdata={})
      #
      res = Response.new
      res.set_sysdata sysdata

      #
      res.sysdata[:cluster_id] = cluster.id

      gex_logger.debug('debug_provision', "run provision delete_cluster_all - start", res.sysdata)

      # run provision
      script = Gexcore::Provision::Service.build_provisioner_cmd(
          'run/delete_cluster_all.rb',
          "_cluster_id=#{cluster.id} _node_ids='#{node_ids}' "
      )
      res_provision = Gexcore::Provision::Service.run('delete_cluster_all', script)


      # result
      gex_logger.debug_response(res_provision, 'provision result', res.sysdata)


      # rollback
      if res_provision.error?
        return res.set_error('cluster_uninstall_error', 'Cannot uninstall cluster', 'Cannot run ansible script')
      end

      res_provision
    end



    ### update container route

    def self.update_container_route(node, ip)
      raise 'not used'

      gex_logger.debug('debug_provision',"update_container_route - start", {node_id: node.id, ip: ip})

      #
      args = %Q{_cluster_id=#{node.cluster_id} _node_id=#{node.id} _ip_address=#{ip} }
      #cmd = Gexcore::Provision::Service.build_cmd_ansible "update_container_route.yml", args
      cmd = Gexcore::Provision::Service.build_cmd_cap("update_container_route", args)
      res_provision = Gexcore::Provision::Service.run("update_container_route", cmd)

      if res_provision.error?
        return res.set_error('update_container_route_error', 'Cannot update container', 'Cannot run provision script')
      end

      res_provision
    end



  end
end

