module Gexcore::Nodes
  class Provision < Gexcore::BaseService


    ### create node

    def self.provision_master_create_node(node, sysdata={}, script_opts={})
      # input
      if node.kind_of? Integer
        node_id = node
        node = Node.find(node_id)
      end

      #
      res = Response.new
      res.set_sysdata sysdata

      #
      gex_logger.debug('provision_start',"run provision create_node - start", {node_id: node.id, opts: script_opts})

      # save data to consul
      Gexcore::Nodes::Service.consul_update_node_data(node)

      # add web services
      Gexcore::Nodes::Service.consul_update_web_services(node)

      gex_logger.debug('provision_start',"after consul_update_web_services", {node_id: node.id})

      # provision
      #node_data = build_params_node_data(node, 'hash')
      script = Gexcore::Provision::Service.build_cmd_cap(
          'provision:create_node',
          #"_cluster_id=#{node.cluster_id} _node_id=#{node.id} _node_data='#{node_data.to_json}'"
          "_cluster_id=#{node.cluster_id} _node_id=#{node.id} "
      )

      res_provision = Gexcore::Provision::Service.run('create_node', script)

      gex_logger.debug("provision_result", "Provision master create_node - result", {node_id: node.id, res: res_provision.success?})


      # error
      if res_provision.error?
        # set job error
        node.set_error_job_task('install', 'master')

        # rollback
        if Rails.env.production?
          res_provision_uninstall = Gexcore::Nodes::Provision::provision_master_uninstall_node(node, sysdata)
        end

        # error
        return res.set_error('node_install_error', 'Cannot create node', 'Cannot run provision script')
      end

      # OK
      # finish job
      node.finish_job_task('install', 'master')


      res.set_data
    end


    def self.provision_master_uninstall_node(node, sysdata={})
      if node.is_a?(Integer)
        node_id = node
        node = Node.get_by_id(node_id)
      end

      #
      res = Response.new
      res.set_sysdata sysdata

      #
      gex_logger.debug('debug_provision',"run provision remove_node - start", {node_id: node.id})

      # provision
      #args = ansible_script_params_create_node(node)
      #cmd = Gexcore::Provision::Service.build_cmd_ansible "remove_node.yml", args
      #res_provision = Gexcore::Provision::Service.run("remove_node", cmd)

      # v2 - cap
      script = Gexcore::Provision::Service.build_cmd_cap(
          'provision:remove_node',
          "_cluster_id=#{node.cluster_id} _node_id=#{node.id} "
      )

      res_provision = Gexcore::Provision::Service.run('remove_node', script)


      if res_provision.error?
        node.set_error_job_task('uninstall', 'master')
        node.set_uninstall_error!
        return res.set_error('node_uninstall_error', 'Cannot uninstall node', 'Error in script remove_node')
      end


      # OK
      node.finish_job_task('uninstall', 'master')

      # finish uninstall
      #node.finish_uninstall!

      #
      res.set_data
    end



    # helpers for provision script params





    ###
    def self.filename_properties_node(node)
      "#{Gexcore::Settings.dir_clusters_data}#{node.cluster_id}/nodes/#{node.node_number}/node.json"
    end



  end
end
