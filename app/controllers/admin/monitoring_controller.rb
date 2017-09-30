class Admin::MonitoringController < Admin::MyAdminBaseController


  def show_servers
    @servers =  Gexcore::SystemService.servers

    # counters
    @counters = []
    @servers.each do |server_name, server|
      state = Gexcore::Monitoring::SystemMonitoringService.get_server_state_keepalive server
      counters = Gexcore::Monitoring::SystemMonitoringService.get_server_state_performance(server)

      @counters << {
          id: server[:id],
          state: state,
          counters: counters
      }
    end



    #
    respond_to do |format|
      format.html {

      }
      format.json {
        render json: @counters
      }
    end
  end


  def show_nodes
    @cluster_id = params[:id]

    @cluster = Cluster.find(@cluster_id)

    #
    @nodes = Node.where(cluster_id: @cluster_id).order("id desc").limit(100)

    # counters
    @res = []
    @nodes.each do |node|
      checks = Gexcore::Monitoring::NodesMonitoring.get_checks_for_node(node)
      counters = Gexcore::Monitoring::NodesMonitoring.get_node_state_performance(node)

      @res << {
          id: node.id,
          checks: checks,
          counters: counters
      }
    end

    #
    respond_to do |format|
      format.html {      }
      format.json {        render json: @res      }
    end
  end
end
