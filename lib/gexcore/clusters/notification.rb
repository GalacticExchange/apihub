module Gexcore::Clusters
  class Notification < Gexcore::BaseService

    def self.notify(cluster_event_name, params)

      cluster_id = params['cluster_id']
      cluster = Cluster.find(cluster_id)

      return Response.res_error('', 'Cluster not found', "bad id for cluster: #{cluster_id}") if cluster.nil?

      # ignore notification if cluster removed
      if cluster.removed?
        return Response.res_error('notify_cluster_removed', 'cluster removed', "cannot change removed cluster - event #{cluster_event_name}", 404)
      end

      #
      gex_logger.info "notify_cluster", "cluster event #{cluster_event_name}", {cluster_id: cluster_id, params: params}

      mtd = :"notify_#{cluster_event_name}"

      if !Gexcore::Clusters::Notification.respond_to?(mtd)
        gex_logger.info "notify_cluster_error", "Bad event #{cluster_event_name}", {cluster_id: cluster_id, params: params}

        return Response.res_error('notify_cluster_error', "Bad event #{cluster_event_name}")
      end

      return Gexcore::Clusters::Notification.send(mtd, cluster)
    end


    def self.notify_installed(cluster)
      res = Response.new

      res_status = cluster.finish_install!
      unless res_status
        return  res.set_error("cluster_install_error", 'Cannot change cluster status')
      end

      res.set_data
    end

    def self.notify_provision_uninstall_error(cluster)
      # todo - check current status
      cluster.set_uninstall_error!
      Response.res_data
    end

    def self.notify_provision_uninstalled(cluster)
      # todo - check current status
      res = Response.new

      res_status = cluster.finish_uninstall!

      ## todo
      if !res_status
        return  res.set_error("cluster_uninstall_error", 'Cannot change cluster status')
      end

      res.set_data
    end


  end
end