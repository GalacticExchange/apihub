class MonitoringChecksController < AccountBaseController
  layout "sidebar_view"

  def list_for_nodes
    #
    @res = Gexcore::Response.new

    # input
    @uids = params[:ids].split(",").map { |s| s.to_i }

    @res_checks = Gexcore::Monitoring::NodesMonitoring.get_checks_for_nodes_by_user(current_user, @uids)

    @res.set_data(@res_checks)
    return_json(@res)
  end


  def list_for_services

    @res = Gexcore::Response.new

    # input
    @ids = params[:ids]

    services_uids = params[:ids]
    services_uids = services_uids.split(",").map { |s| s.to_i }

    #
    @res_checks = Gexcore::Monitoring::ServicesMonitoring.get_for_services_by_user(current_user, services_uids)

    @res.set_data(@res_checks)
    return_json(@res)
  end

  def list_for_containers

    @res = Gexcore::Response.new

    cont_uids = params[:ids]
    cont_uids = cont_uids.split(",").map { |s| s.to_i }

    @res_checks = Gexcore::Monitoring::ContainersMonitoring.get_for_containers_by_user(current_user, cont_uids)

    @res.set_data(@res_checks)
    return_json(@res)
  end


  def container
    @res = Gexcore::Response.new

    cont_uid = params[:containerId]
    container = ClusterContainer.get_by_uid(cont_uid)

    unless container
      @res.set_error_badinput('container_not_found', 'Container not found')
      return return_json(@res)
    end

    @res_checks = Gexcore::Monitoring::ContainersMonitoring.get_for_container(container)

    @res.set_data(@res_checks)
    return_json(@res)
  end

  def node
    @res = Gexcore::Response.new

    node_uid = params[:nodeId]
    node = Node.get_by_uid(node_uid)

    unless node
      @res.set_error_badinput('node_not_found', 'Node not found')
      return return_json(@res)
    end

    @res_checks = Gexcore::Monitoring::NodesMonitoring.get_checks_for_node(node)

    @res.set_data(@res_checks)
    return_json(@res)
  end


  def get_checks_for_container

    cont_uid = params[:id]


  end


end
