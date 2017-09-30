module Gexcore::Containers
  class Notification < Gexcore::BaseService

    ### main method
    def self.notify(event_name, params)
      #
      res = Response.new

      # input
      container_uid = params['containerID']
      if container_uid
        container = ClusterContainer.get_by_uid(container_uid)
      else
        container_id = params[:container_id]
        if container_id
          container = ClusterContainer.find(container_id)
        end
      end

      return res.set_error('', 'Container not found', "bad id for container") if container.nil?

      #
      res.sysdata[:container_id] = container.id

      # ignore notification if removed
      if container.removed?
        return res.res_error('notify_container_removed', 'cannot change removed container', "cannot change removed container - event #{event_name}", 404)
      end

      #
      gex_logger.info "notify_container", "Container event #{event_name}", {params: params}

      #
      mtd = :"notify_#{event_name}"
      if !Gexcore::Containers::Notification.respond_to?(mtd)
        gex_logger.info "notify_container_error", "Bad event #{event_name}", {params: params}

        return res.set_error('notify_container_error', "Bad event #{event_name}")
      end

      return Gexcore::Containers::Notification.send(mtd, container)
    end


    # start

    def self.notify_started(container)
      res_event = container.finish_start!

      return return_res_event(res_event, 'container_started')
    end

    def self.notify_start_error(container)
      res_event = container.set_start_error!

      return return_res_event(res_event, 'container_start_error')
    end


    # restart
    def self.notify_restarted(container)
      res_event = container.finish_restart!

      #
      return return_res_event(res_event, 'container_restarted')
    end

    def self.notify_restart_error(container)
      res_event = container.set_restart_error!

      return return_res_event(res_event, 'container_restart_error')
    end

    # stop
    def self.notify_stopped(container)
      res_event = container.finish_stop!
      return return_res_event(res_event, 'container_stopped')
    end

    def self.notify_stop_error(container)
      res_event = container.set_stop_error!
      return return_res_event(res_event, 'container_stop_error')
    end



    ### helpers

    def self.return_res_event(res_event, event_name='')
      if !res_event
        return  Response.res_error("container_change_status_error", 'Cannot change container status',"error changing status: event=#{event_name} ")
      end

      return Response.res_data
    end


  end
end

