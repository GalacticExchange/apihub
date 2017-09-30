module LogsHelpers

  def log_data(p={})
    data = p

    #
    data[:source] ||= 'server'
    data[:level] ||= 'info'
    data[:type] ||= 'error_general'
    data[:message] ||= 'something bad occurred'

    #teamID, clusterID, nodeID

    data[:data] ||= {'v1'=>'me', 'v2'=>'you'}

    data[:version] ||= '0.0.1'

    data
  end

  def post_log(p_data, token)
    data = log_data(p_data)

    # add log_type to DB
    row_type = LogType.get_by_name_or_create(data[:type])
    LogType.make_visible_client(row_type.id)

    # work
    post_json '/log', data, {token: token}


    resp = last_response
    resp_data= JSON.parse(resp.body)

    # give time to ES to update index
    sleep 3

    resp_data
  end

  def elvis_post_log(p_data, token)
    data = log_data(p_data)

    # add log_type to DB
    LogType.get_by_name_or_create(data[:type])
    #LogType.make_visible_client(row_type.id)

    # work
    post_json '/log', data, {token: token}

    # give time to ES to update index
    sleep 3

    resp = last_response
    resp_data= JSON.parse(resp.body)

    resp_data
  end

  def elvis_invisible_post_log(p_data, token)
    data = log_data(p_data)

    # add log_type to DB
    row_type = LogType.get_by_name_or_create(data[:type])
    LogType.make_invisible_client(row_type.id)

    # work
    post_json '/log', data, {token: token}

    # give time to ES to update index
    sleep 3

    resp = last_response
    resp_data= JSON.parse(resp.body)

    resp_data
  end
end
