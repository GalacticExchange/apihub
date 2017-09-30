module Gexcore::Nodes::Aws
  class Provision < Gexcore::BaseService


    ## create - node
    # run two provisions
    def self.create_node(node, sysdata={})
      # input
      if node.kind_of? Integer
        node_id = node
        node = Node.find(node_id)
      end

      #
      res = Response.new
      res.set_sysdata sysdata

      # provision 1
      res_provision1 = Gexcore::Nodes::Provision.provision_master_create_node(node, sysdata)
      return res_provision1 if res_provision1.error?

      # provision 2
      res_provision2 = create_node_aws_instance(node, sysdata)
      return res_provision2      if res_provision2.error?


      res.set_data
    end


    ### create Node - aws

    def self.create_node_aws_instance(node, opts={})
      # input
      if node.is_a? Integer
        node_id = node
        node = Node.get_by_id node_id
      end

      #
      res = Response.new
      res.sysdata[:node_id] = node.id
      res.set_data

      #
      gex_logger.debug('node_provision_aws_instance_starting',"start provision create_node_aws_instance", {node_id: node.id})


      # save data to consul
      Gexcore::Nodes::Service.consul_update_node_data(node)

      # run provision script
      #node_data = build_params_node_data_aws_instance(node, opts, 'hash')
      script = Gexcore::Provision::Service.build_cmd_cap(
          'provision:create_node_aws_instance',
          #"_cluster_id=#{node.cluster_id} _node_id=#{node.id} _node_data='#{node_data.to_json}'"
          "_cluster_id=#{node.cluster_id} _node_id=#{node.id} "
      )

      res_provision = Gexcore::Provision::Service.run('create_node_aws_instance', script)


      gex_logger.debug('node_provision_aws_instance_result',"provision result",
                       {script: "create_node_aws_instance", node_id: node.id, res: res_provision.success?})

      if res_provision.error?
        gex_logger.error('node_provision_aws_instance_error',"provision create_node_aws_instance - ERROR",
                         {script: "create_node_aws_instance", node_id: node.id})

        node.set_error_job_task('install', 'aws_instance')
        #  res_clean_ansible = Gexcore::Provision::run_script_ansible("rollback_create_node_aws_instance.yml", args)
        return res.set_error('node_provision_aws_instance_error', 'Cannot create node', 'Cannot run script create_node_aws_instance')
      end

      # OK
      node.finish_job_task('install', 'aws_instance')

      res.set_data
    end




    ### control commands

    def self.start_node(node)
      gex_logger.debug "debug_provision", "provision start_node - start", {node_id: node.id}

      #p = params_for_script_change_node_state(node)
      #cmd = %Q(cd #{config.provision_basedir} && #{p} _action=start ruby cloud/use_ami/change_node_state.rb)
      #return Gexcore::Provision::Service.run("start_node", cmd)

      return run_script_change_aws_node_state(node, 'start')
    end

    def self.stop_node(node)
      gex_logger.debug "debug_provision", "provision stop_node - start", {node_id: node.id}

      #p = params_for_script_change_node_state(node)
      #cmd = %Q(cd #{config.provision_basedir} && #{p} _action=stop ruby cloud/use_ami/change_node_state.rb)
      #return Gexcore::Provision::Service.run("stop_node", cmd)

      return run_script_change_aws_node_state(node, 'stop')
    end

    def self.restart_node(node)
      gex_logger.debug "debug_provision", "provision restart_node - start", {node_id: node.id}

      #p = params_for_script_change_node_state(node)
      #cmd = %Q(cd #{config.provision_basedir} && #{p} _action=restart ruby cloud/use_ami/change_node_state.rb)
      #return Gexcore::Provision::Service.run("restart_node", cmd)

      return run_script_change_aws_node_state(node, 'restart')
    end


    def self.run_script_change_aws_node_state(node, cmd, sysdata={})
      script = Gexcore::Provision::Service.build_cmd_cap(
          "provision:change_aws_node_state",
          "_cluster_id=#{node.cluster_id} _node_id=#{node.id} _action=#{cmd}"
      )


      # save data to consul
      #container_data = build_container_data(container, 'hash')
      #Gexcore::Consul::Service::update_container_data(container, container_data)


      # run provision
      res_provision = Gexcore::Provision::Service.run("change_aws_node_state_#{cmd}", script)

      #
      gex_logger.debug('node_provision_result',"provision result", {cmd: cmd, node_id: node.id, res: res_provision.success?})


      res_provision
    end



    ### uninstall

    def self.uninstall_node(node, sysdata={})
      if node.is_a?(Integer)
        node_id = node
        node = Node.get_by_id(node_id)
      end

      #
      res_provision = Gexcore::Nodes::Provision.provision_master_uninstall_node(node, sysdata)

      # if provision ok => consider client is uninstalled
      if res_provision.success?
        node.finish_job_task('uninstall', 'client')
      end

    end

    ### run script

    def self.params_for_script_change_node_state(node)
      "_cluster_id=#{node.cluster_id} _node_id=#{node.id} _node_uid=#{node.uid}"
    end






  end
end
