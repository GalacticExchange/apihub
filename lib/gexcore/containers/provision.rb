module Gexcore::Containers
  class Provision < Gexcore::BaseService


    ### main method

    def self.run_control_command(container, cmd, env={})
      # input
      if container.is_a? Integer
        container_id = container
        container = ClusterContainer.get_by_id container_id
      end

      #
      res = Response.new
      res.sysdata[:container_id] = container.id
      res.set_data


      # run provision script
      return send("#{cmd}", container)
    end


    ### run commands

    def self.restart(container, opts={})
      res = Gexcore::Response.new

      #
      cmd = 'restart'

      #
      if container.node_id
        raise 'not supported'
      else
        res_provision = run_master_container_control_script(container, cmd)
      end


      if res_provision.error?
        res_event = container.set_restart_error!
        return res.set_error('container_provision_error', 'Cannot provision container', 'Cannot run provision script')
      end


      # finish
      container.finish_restart!

      res_provision


    end

    def self.start(container, opts={})
      res = Gexcore::Response.new

      #
      cmd = 'start'

      if container.node_id
        raise 'not supported'
      else
        res_provision = run_master_container_control_script(container, cmd)
      end

      if res_provision.error?
        container.set_start_error!
        return res.set_error('container_provision_error', 'Cannot provision container', 'Cannot run provision script')
      end

      # finish
      container.finish_start!

      #
      res_provision
    end


    def self.stop(container, opts={})
      res = Gexcore::Response.new

      #
      cmd = 'stop'

      if container.node_id
        raise 'not supported'
      else
        res_provision = run_master_container_control_script(container, cmd)
      end


      if res_provision.error?
        container.set_stop_error!
        return res.set_error('container_provision_error', 'Cannot provision container', 'Cannot run provision script')
      end

      # finish
      container.finish_stop!

      #
      res_provision
    end






    ## helpers


    def self.build_container_data(container, format="hash")
      cluster = container.cluster

      # params
      h = {}

      # basic params
      h.merge!({
                   id: container.id,
                   uid: container.uid,
                   name: container.name,
                   basename: container.basename,
                   hostname: container.hostname,
                   public_ip: container.get_local_ip,
                   #private_ip: container.get_gex_ip,

                   application_id: container.application_id,

                   node_id: container.node_id,

                   cluster_id: cluster.id,
                   cluster_type: cluster.cluster_type_name,
               })



      return Gexcore::Provision::Service.params_hash_format(h, format)
    end




    # OLD 2017-05-17
=begin
    def self.build_script_for_command(container, cmd, opts={})
      args = params_control_command(container, cmd)
      script_name = 'container_control.rb'

      full_path = File.join(config.provisioner_dir, script_name)

      #
      %Q(#{args} ruby #{full_path})


    end
=end


=begin
    def self.params_control_command(container, cmd, opts={})
      #"clusterID=#{container.cluster.id} containerID=#{container.id} containerName=#{container.name} cmd=#{cmd}"
      s_base = " _cluster_id=#{container.cluster_id} _container_name=#{container.name} _cmd=#{cmd}"
      if container.is_master?
        # node_id should be nil
        s_extra = " "
      else
        node = container.node
        s_extra = " _node_id=#{node.id} _node_name=#{node.name} _node_uid=#{node.uid}"
      end


      s_base+s_extra
    end
=end


    ###

    def self.run_master_container_control_script(container, cmd, sysdata={})
      container_data = build_container_data(container, 'hash')

      script = Gexcore::Provision::Service.build_cmd_cap(
          "provision:change_master_container_state",
          "_cluster_id=#{container.cluster_id} _container_id=#{container.id} _app_name=#{container.basename} _action=#{cmd}"
      )


      # save data to consul
      Gexcore::Consul::Service::update_container_data(container, container_data)


      # run provision
      res_provision = Gexcore::Provision::Service.run("change_master_container_state_#{cmd}", script)

      #
      gex_logger.debug('container_provision_result',"provision result", {cmd: cmd, container_id: container.id, res: res_provision.success?})


      res_provision
    end


  end
end
