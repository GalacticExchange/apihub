module Gexcore::Nodes
  class Notification < Gexcore::BaseService

    ### general method
    def self.notify_node(node_event_name, params)
      node_uid = params['nodeID']
      if node_uid
        node = Node.get_by_uid(node_uid)
      else
        node_id = params[:node_id] || params['node_id']
        if node_id
          node = Node.find(node_id)
        end

      end

      return Response.res_error('', 'Node not found', "bad uid for node: #{node_uid}") if node.nil?

      # ignore notification if node removed
      if node.removed?
        return Response.res_error('notify_node_removed', 'node removed', "cannot change removed node - event #{node_event_name}", 404)
      end

      #
      gex_logger.info "notify_node", "node event #{node_event_name}", {node_id: node.id, params: params}

      #
      mtd = :"notify_#{node_event_name}"
      if !Gexcore::Nodes::Notification.respond_to?(mtd)
        gex_logger.info "notify_node_error", "Bad event #{node_event_name}", {node_uid: node.uid, params: params}

        return Response.res_error('notify_node_error', "Bad event #{node_event_name}")
      end

      return Gexcore::Nodes::Notification.send(mtd, node)
    end


    # install
    def self.notify_installed(node)
      # finish job
      node.finish_job_task('install', 'client')
      Response.res_data

      # OLD
      #res_event = node.finish_install!
      #return Response.res_error('', 'Wrong node status', 'cannot set installed') if !res_event
      #Response.res_data
    end

    def self.notify_install_error(node)
      # error job
      node.set_error_job_task('install', 'client')

      Response.res_data

      # OLD
      #res_event = node.set_install_error!
      #return return_res_event(res_event, 'install_error')
    end


    def self.notify_client_installed(node)
      # finish job
      node.finish_job_task('install', 'client')

      #
      Response.res_data
    end

    def self.notify_client_install_error(node)
      # error job
      node.set_error_job_task('install', 'client')

      #
      Response.res_data
    end


    # start

    def self.notify_started(node)
      res_event = node.finish_start!

      #
      return return_res_event(res_event, 'node_started')
    end

    def self.notify_start_error(node)
      res_event = node.set_start_error!

      return return_res_event(res_event, 'node_start_error')
    end

    # restart

    def self.notify_restarted(node)
      res_event = node.finish_restart!

      #
      return return_res_event(res_event, 'node_restarted')
    end

    def self.notify_restart_error(node)
      res_event = node.set_restart_error!

      return return_res_event(res_event, 'node_restart_error')
    end

    # stop
    def self.notify_stopped(node)
      res_event = node.finish_stop!
      return return_res_event(res_event, 'node_stopped')
    end

    def self.notify_stop_error(node)
      res_event = node.set_stop_error!
      return return_res_event(res_event, 'node_stop_error')
    end


    # uninstall
    def self.notify_uninstalling(node)
      #res_event = node.begin_uninstall!
      #return return_res_event(res_event, 'node_uninstalling')

      return Gexcore::Nodes::Service.uninstall_node(node)
    end

    def self.notify_uninstalled(node)
      gex_logger.info "notify_node_uninstalled", "notify - uninstalled", {node_id: node.id}

      # finish job
      node.finish_job_task('uninstall', 'client')
      Response.res_data

      # OLD
      #res_event = node.finish_uninstall!
      #return return_res_event(res_event, 'node_uninstalled')
    end

    def self.notify_uninstall_error(node)
      # error job
      node.set_error_job_task('uninstall', 'client')
      Response.res_data


      # OLD
      #res_event = node.set_uninstall_error!
      #return return_res_event(res_event, 'node_uninstall_error')
    end



    # provision notify

    def self.notify_provision_uninstall_error(node)
      # error job
      node.set_error_job_task('uninstall', 'client')
      Response.res_data
    end

    def self.notify_provision_uninstalled(node)
      gex_logger.info "notify_node_uninstalled", "notify - uninstalled", {node_id: node.id}

      # finish job
      node.finish_job_task('uninstall', 'client')
      Response.res_data
    end


    # remove

=begin
    def self.notify_node_removed(node)
      return Nodes::Service.remove_node(node)
    end

    def self.notify_node_remove_error(node)
      res_event = node.set_remove_error!

      #
      return return_res_event(res_event, 'remove_error')
    end
=end


    ### helpers

    def self.return_res_event(res_event, event_name='')
      if !res_event
        return  Response.res_error("node_change_status_error", 'Cannot change node status',"error changing status: event=#{event_name} ")
      end

      return Response.res_data
    end


  end
end

