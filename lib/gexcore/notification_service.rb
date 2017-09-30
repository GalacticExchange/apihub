module Gexcore
  class NotificationService < BaseService

    def self.notify(event_name, params)
      event_name = event_name.downcase
      gex_logger.debug "notify", "event #{event_name}", {params: params}

      if event_name =~ /^cluster\_(.*)$/i
        cluster_event_name = $1
        return Gexcore::Clusters::Notification.notify(cluster_event_name, params)
      elsif event_name =~ /^node\_(.*)$/i
        node_event_name = $1
        return Gexcore::Nodes::Notification.notify_node(node_event_name, params)
      elsif event_name =~ /^container\_(.*)$/i
        container_event_name = $1
        return Gexcore::Containers::Notification.notify(container_event_name, params)
      elsif event_name =~ /^application\_(.*)$/i
        app_event_name = $1
        return notify_application(app_event_name, params)
      else
        res = Response.res_error_badinput('notify', 'unknown event', "event not found #{event_name}")
      end

      res
    end


    def self.notify_application(app_event_name, params)
      app_uid = params['applicationID'] || params[:applicationID]
      if app_uid
        app = ClusterApplication.get_by_uid(app_uid)
      else
        app_id = params[:app_id]
        if app_id
          app = ClusterApplication.find(app_id)
        end
      end

      return Response.res_error('', 'Application not found', "bad uid for app: #{app_uid}") if app.nil?

      # node
      #node_uid = params['nodeID'] || params[:nodeID]
      #if node_uid
      #  node = Node.get_by_uid(node_uid)
      #end
      #return Response.res_error('', 'Node not found', "bad uid for node: #{node_uid}") if node.nil?


      # ignore notification if app removed
      if app.removed?
        return Response.res_error('notify_app_removed', 'App removed', "cannot change removed app", 404)
      end

      # check application belongs to node
      #if app.cluster_id!=node.cluster_id
      #  return Response.res_error('notify_application_error', 'Wrong application', "App doesn't belong to the cluster", 404)
      #end

      # check application belongs to cluster
      #if app.cluster_id!=node.cluster_id
      #  return Response.res_error('notify_application_error', 'Wrong application', "App doesn't belong to the cluster", 404)
      #end

      #
      gex_logger.info "notify_application", "Application event #{app_event_name}", {application_uid: app.uid, params: params}

      #
      mtd = :"notify_#{app_event_name}"
      if !Gexcore::NotificationApplicationService.respond_to?(mtd)
        gex_logger.info "notify_application_error", "Bad event #{app_event_name}", {node_uid: node.uid, application_uid: app.uid, params: params}

        return Response.res_error('notify_application_error', "Bad event #{app_event_name}")
      end

      return Gexcore::NotificationApplicationService.send(mtd, app)
    end



  end
end

