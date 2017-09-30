class PermissionsController < AccountBaseController

  def check
    # input:
    # nodeAgentToken - in headers
    # token - user token
    # operation

    # auth
    init_auth_data

    if @res_auth.error?
      return_json(Gexcore::Response.set_error_forbidden('auth_error', "Not authorized", "Not authorized")) and return
    end

    # check permission
    mtd_check = :"check_#{params[:operation]}"
    if respond_to?(mtd_check)
      res = send(mtd_check)
    else
      # not supported
      return_json(Gexcore::Response.set_error_badinput('bad_request', "Bad request", "Permissions check: operation not supported")) and return
    end

    return_json(res)
  end




  def check_nodeViewLogs
    # initiator - node agent

    # input - user
    token = params[:userToken]

    # validate user token
    res_validate = Gexcore::AuthService.validate_token(token)
    if res_validate.error?
      return Gexcore::Response.res_error_badinput("bad_request", "User not found", "Token invalid")
    end

    #
    @user = User.get_by_username(res_validate.data[:username])

    # node
    if @res_auth.data[:agent_node_uid].present?
      @node_uid ||= @res_auth.data[:agent_node_uid]
    end

    @node = Node.get_by_uid @node_uid
    if @node.nil?
      return Gexcore::Response.res_error_badinput("", "Node not found")
    end

    # check permissions
    if !(@user.can? :view_node_logs, @node)
      return Gexcore::Response.res_error_forbidden("permission_forbidden", 'No permissions to view logs for this node')
    end

    # ok - permitted
    Gexcore::Response.res_data
  end


end

