class AuthController < BaseController

  def login
    # input
    username = params['username'] || ''
    pwd = params['password'] || ''
    sysinfo = params['systemInfo'] || {}

    # work
    res = Gexcore::AuthService.auth(username, pwd, sysinfo)

    if res.success?
      # devise login user
      sign_in(:user, User.get_by_username_or_email(username))
      # add to logs
      gex_logger.info('user_logged_in', 'User logged in', {user_status: 'User logged in'})
      #
      my_after_login_callback(res.data[:token])
    end

    #
    return_json(res)
  end

  def logout
    # validate token
    init_auth_data

    if @res_auth.error?
      return (return_json @res_auth)
    end

    # work
    @token = @res_auth.data[:token] || get_token_from_request
    @res = Gexcore::AuthService.invalidate_token(@token)

    # logout with devise
    if current_user
      sign_out current_user
    end

    #
    return_json(@res)
  end




  def refresh_token
    # input
    token = params['token'] || ''
    agent_token = params['nodeAgentToken'] || ''

    # work
    res = Gexcore::AuthService.refresh(token, agent_token)

    #
    return_json(res)

  end

  def auth_access_cluster
    #input
    format = params[:format] || 'json'
    @token = params[:token]
    @username = params[:username]
    @hostname = params[:hostname]

    #
    data = {access: "0"}

    begin
      # parse jwt token
      res_validate = Gexcore::AuthService.validate_token @token

      # debug
      #res_validate = Gexcore::Response.res_data(username: @username)

      raise 'Invalid token' if res_validate.error?

      token_data = res_validate.data
      if token_data[:username]!=@username
        raise 'Username and token mismatch'
      end


      # get cluster from hostname
      res_parse_cluster = Gexcore::DnsService.parse_master_hostname(@hostname)
      if res_parse_cluster
        @cluster = Cluster.get_by_id(res_parse_cluster[1].to_i)
      elsif res_parse_node = Gexcore::DnsService.parse_node_hostname(@hostname)
        node = Node.get_by_name(res_parse_node[1])
        raise 'Node not found' if node.nil?
        @cluster = node.cluster
      end

      raise 'Cluster not found' if @cluster.nil?


      #
      @user = User.get_by_username @username

      res_access = Gexcore::ClustersAccessService.has_access?(@user, @cluster)

      gex_logger.debug("debug", "access to cluster #{@cluster.id} from user #{@user.id} = #{res_access.inspect}")

      if res_access
        data[:access] = "1"
        data[:username] = @username
        data[:teamName] = @user.team.name
      end

    rescue => e
      gex_logger.debug_exception("debug_auth_access_cluster", 'no access', e)
    end


    #
    if format=='json'
      return_json_data(data)
    elsif format=='string'
      s_res = ""
      if data[:access]=="1"
        s_res = "#{data[:teamName]}"
      else
        s_res = ""
      end

      render plain: s_res
    end

  rescue


  end

end
