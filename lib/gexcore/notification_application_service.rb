module Gexcore
  class NotificationApplicationService < BaseService

    # install
    def self.notify_installed(app)
      res_event = app.finish_install!
      return Response.res_error('', 'Wrong application status', 'cannot set installed') if !res_event
      Response.res_data
    end

    def self.notify_install_error(app)
      res_event = app.set_install_error!

      #
      return return_res_event(res_event, 'install_error')
    end


=begin

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

=end

    # uninstall
    def self.notify_uninstalling(app)
      res_event = app.begin_uninstall!
      return return_res_event(res_event, 'app_uninstalling')
    end

    def self.notify_uninstalled(app)
      res_event = app.finish_uninstall!
      return return_res_event(res_event, 'app_uninstalled')
    end

    def self.notify_uninstall_error(app)
      res_event = app.set_uninstall_error!
      return return_res_event(res_event, 'app_uninstall_error')
    end



    ### helpers

    def self.return_res_event(res_event, event_name='')
      if !res_event
        return  Response.res_error("application_change_status_error", 'Cannot change application status',"error changing status: event=#{event_name} ")
      end

      return Response.res_data
    end



  end
end

