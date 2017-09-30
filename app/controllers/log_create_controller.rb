class LogCreateController < BaseController

  def create
    # not supported
    return_json_data({res: 0, message: 'not supported'})
    return

    # authorize request
    init_auth_data

    if @res_auth.error?
      # try by team id
      #team = Team.get_by_uid params[:teamID]
      #return (return_json @res_auth) if team.nil?

      # try with instance id
      @instance_id = params[:instanceID]
      return (return_json @res_auth) if @instance_id.nil?
    end

    # input data
    version = params['version'] || ''

    # level
    level = params['level'] || Gexcore::Logger.LEVEL_DEFAULT

    # msg
    msg = params['message'] || ''

    # source
    source_name = params['source'] || ''
    source_name = source_name.to_s.downcase


    # type
    type_name = params['type'] || ''
    type_name = type_name.to_s.downcase
    #subtype_name = params['subtype'] || ''

    # cluster, node
    cluster_uid = params[:clusterID] || nil
    node_uid = params[:nodeID] || nil

    #
    user_id = nil
    user = current_user if current_user

    if @res_auth.data[:agent_node_uid].present?
      node_uid ||= @res_auth.data[:agent_node_uid]
    end

    # data
    data = {}
    body_data = params['data'] || {}
    if body_data.is_a?(Hash)
      data['data'] = body_data
    else
      data['data'] = {body: body_data}
    end

    data['data']['systemInfo'] = params['systemInfo'] || {}
    data['data']['error'] = params['error'] || {}

    data[:user_id] = user.id if user
    data[:team_id] = user.team_id if user

    #if team.nil?
    #if xxxxxx.nil?
    #  gex_logger.debug('debug_log', 'debug log', {teamok: 1})
    #end

    #data[:team_id] = team.id if !(team.nil?)

    team_id = params[:teamID]

    if data[:team_id].nil? && team_id
      #data[:team_id] = team.id if !team.nil?
      data[:team_id] = team_id
    end
    #gex_logger.debug('debug_log', 'debug log', {team: team})



    # ip
    data[:ip] = request.ip

    # instance id
    data[:instance_id] = params[:instanceID]

    # cluster
    cluster_id = nil
    if !cluster_uid.nil?
      cluster = Cluster.get_by_uid cluster_uid
      cluster_id = cluster.id if cluster
    #else
    #  cluster_id = user ? user.main_cluster_id : nil
    end

    data[:cluster_id] = cluster_id

    # node
    data[:node_uid] = node_uid if node_uid.present?

    # cluster, node, instance
    data[:clusterID] = params[:clusterID] || nil
    data[:nodeID] = params[:nodeID] || nil
    data[:instanceID] = params[:instanceID] || nil

    #
    res_log = Gexcore::GexLogger.log(version, source_name, level, msg, type_name, data)

    return_json_data({})
  end


end
