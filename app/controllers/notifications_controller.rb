class NotificationsController < BaseController
  before_action :init_data


  def init_data
    # authorize request
    init_auth_data

    if @res_auth.error?
      return (return_json @res_auth)
    end
  end


  def create
    # input
    event_name = params['event'] || ''
    desc = params['description'] || ''
    cluster_uid = params['clusterID'] || ''
    node_uid = params['nodeID'] || ''
    container_uid = params['containerID'] || ''
    app_uid = params['applicationID'] || ''


    # check node belongs to agent
    if @res_auth.error?
      return_json Gexcore::Response.res_error_forbidden("", "Bad request", "") and return
    end

    # auth
    if !current_user
      @node_of_agent = Node.get_by_uid(@res_auth.data[:agent_node_uid])

      if @node_of_agent.uid!=node_uid.to_s
        return_json Gexcore::Response.res_error_forbidden("", "Wrong node", "") and return
      end
    end


    # some checks
    if event_name.empty?
      return_json Gexcore::Response.res_error_badinput("", "Event is empty", "") and return
    end

    #if cluster_uid.empty?
    #  return_json Gexcore::Response.res_error_badinput("", "Cluster is empty", "") and return
    #end

    if !app_uid.empty?
      app = ClusterApplication.get_by_uid(app_uid)

      # check
      if !auth_request_for_app(app)
        return_json Gexcore::Response.res_error_forbidden("", "Bad request", "") and return
      end

    end

    # process notification
    res = Gexcore::NotificationService.notify(event_name, params)

    return_json res
  end


  # return true if auth is ok
  # means - node agent or logged in user posseses this app
  def auth_request_for_app(app)
    if current_user
      return current_user.can? :manage, app
    else
      # from agent
      node_uid = params['nodeID'] || ''

      #@node_of_agent = Node.get_by_uid(@res_auth.data[:agent_node_uid])

      if @node_of_agent.uid!=node_uid.to_s
        return_json Gexcore::Response.res_error_forbidden("", "Wrong node", "") and return false
      end

      return true
    end

    false
  end
end

