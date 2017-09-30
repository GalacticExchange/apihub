require 'versionomy'

class BaseController < ApplicationController
  include AuthCommon


  before_action :_before_all
  before_action :check_client_version, if: :json_request?


  def _before_all
    # log
    Gexcore::Settings.ip = request.remote_ip
    log_request_start

    #
    check_client
    set_def_permissions

    # location
    store_current_location
  end

  # check app or web
  def check_client
    #@isClient = true
    s_agent = request.user_agent
    @isClient = !s_agent.nil? && s_agent.include?("Electron")
  end

  def set_def_permissions
    @permissions = {
      cluster_manage: false,
      logs: false,
      shares: false
    }
  end



  ###
  def check_client_version
    #
    res = Gexcore::Response.new
    #
    client_version = request.headers['clientVersion']


    if !is_version_supported?(client_version)

      res.set_error('client_version_not_supported', "client not supported: #{client_version}", "client version not supported", nil,
                    {client_version: client_version, min_client_version: Gexcore::Settings.get_client_min_supported_version})

      # log record in DB
      gex_logger.log_response_base(res, :info,
                                   {
                                       path: request.path, method: request.request_method,
                                       request: request_hash_log,
                                   }

      )

      #
      (return_json res) and return false
    end

    true
  end

  def is_version_supported?(client_version)

    client_version.nil? || Versionomy.parse(client_version) >= Versionomy.parse(Gexcore::Settings.get_client_min_supported_version)

  end

  ###
  def return_json(res)
    #content_type :json

    if res.success?
      render :json => res.data
    else
      # log
      gex_logger.debug 'response_error', 'return response', {response: res.inspect, request: request_hash_log}

      #
      render :json => res.get_error_data, :status => res.http_status
    end

  end

  def return_json_data(data)
    render :json => data
  end

  def return_json_ok
    return_json_data({res: 'ok'})
  end

  # auth by token - for API or by current_user
  def authorize_request
    init_auth_data

    # return error
    if @res_auth.error?
      if json_request?
        return_json @res_auth
      else
        u_redirect = params[:from_url] || request.original_url
        if u_redirect
          my_user_store_url_redirect(u_redirect)
        end

        redirect_to new_user_session_path(:from_url=>u_redirect)
        #render_error 403, @res_auth
      end

      return false
    end

    # ok -set data
    if current_user
      #@username = current_user.username
      #@res_auth = Gexcore::Response.res_data
    end

    true
  end

  def init_auth_data
    # auth by token in cookies or headers or params
    @res_auth = validate_user_token

    if @res_auth.error?
      if !@res_auth.data[:token].blank?
        return false
      end
    end

    if @res_auth.success?
      # sign in user by token
      if @res_auth.data[:auth_type]=='token'
        u = User.get_by_username(@res_auth.data[:username])
        sign_in(:user, u)
      end

      #return true
    end

    # auth with Devise - using session_id in cookies
    if current_user

      # check user
      if !Gexcore::AuthService.can_user_login(current_user)
        @res_auth = Gexcore::Response.res_error('user_not_authorized', 'Cannot login', '', 403)
        return false
      end

      #
      @res_auth = Gexcore::Response.res_data({username: current_user.username})

      if @res_auth.success?
        return true
      end
    end


    # by node agent token
    @res_auth = validate_agent_token


  end


  ### helpers for auth


  ### helpers for tokens

  def get_token_from_request
    request.headers['token'] || request.headers['tokenId'] || params['token'] || params['tokenId']
  end

  def validate_user_token
    res_auth = Gexcore::Response.new

    token = get_token_from_request
    token ||= ''
    res_auth.data[:token] = token

    if token.nil? || token.empty?
      return res_auth.set_error_forbidden('auth_user_empty', 'Authorization token not set', "Token not set")
    end

    # validate token
    res_validate = Gexcore::AuthService.validate_token(token)
    if res_validate.error?
      return res_auth.set_error_forbidden(res_validate.error_name, res_validate.error_msg, "Token invalid")
    end

    # OK - return auth data
    return res_auth.set_data(
        {
            auth_type: 'token',
            token: token,
            username: res_validate.data[:username]
        })
  end


  ### helpers for agent tokens

  def get_agent_token_from_request
    request.headers['nodeAgentToken'] || params['nodeAgentToken']
  end

  def validate_agent_token
    res = Gexcore::Response.new

    token = get_agent_token_from_request

    if token.nil? || token.empty?
      return res.set_error_forbidden('auth_agent_empty', 'Authorization token not set', "Token not set")
    end

    # validate token
    res_validate = Gexcore::AuthService.validate_agent_token(token)
    if res_validate.error?
      #
      res.set_error_forbidden(res_validate.error_name, res_validate.error_msg, "Token invalid")

      # log
      gex_logger.log_response_base res, :debug, {}

      #
      return res
    end

    # ok. return auth data
    return res.set_data(
        {
            auth_type: 'agent_token',
            token: token,
            agent_token: token,
            agent_node_id: res_validate.data[:node_id],
            agent_node_uid: res_validate.data[:node_uid]
        })
  end


  ### common helpers

  ### params helpers
  def get_param_value(name)
    params[name] || request.headers[name]
  end


  def get_param_value_hash(name, v_def={})
    p_v = params[name.to_sym] || ""
    s_v = (p_v.to_s rescue '')

    # try 1.
    res = (p_v.to_hash rescue {})

    # try 2
    if res.keys.empty? && s_v.length>0
      res = (JSON.parse(s_v) rescue {})
    end

    res
  end



  ### clusters

  def get_cluster_from_params
    cluster_uid = params[:cluster_uid] || params[:clusterID] || params[:clusterId]
    Cluster.get_by_uid(cluster_uid) if cluster_uid
  end


  def get_cluster_from_session
    cluster_id = session[:current_cluster_id]
    Cluster.get_by_id(cluster_id) if cluster_id
  end

  def find_cluster(cluster)
    if cluster.is_a?(Integer)
      cluster_id = cluster
      cluster = Cluster.get_by_id(cluster_id)
    end
    cluster if cluster && !cluster.removed?
  end


  def set_current_cluster_var(cluster_id)
    @cluster = find_cluster(cluster_id)
    @current_cluster = @cluster if @cluster
  end


  def set_current_cluster_session(cluster_id)
    @cluster = find_cluster(cluster_id)
    session[:current_cluster_id] = @cluster.id if @cluster
  end


  def init_cluster
    return @current_cluster if @current_cluster

    cluster = get_cluster_from_params || get_cluster_from_session
    set_current_cluster_var(cluster)

    @current_cluster
  end


  # to use in controllers
  def check_current_cluster
    init_cluster
    return true if @current_cluster
    return_json(Gexcore::Response.res_error_badinput('', 'wrong cluster id provided', "wrong cluster id provided"))
    false
  end

  # call
  def change_current_cluster
    cluster = get_cluster_from_params || get_cluster_from_session

    res = Gexcore::Response.new

    if cluster && cluster.active?
      set_current_cluster_session(cluster)
      res.set_data
    else
      res.set_error_badinput('', 'wrong cluster id provided', "wrong cluster id provided")
    end

    #
    respond_to do |format|
      format.html{ redirect_to root_path }
      format.json{ return_json(res) }
    end
  end


  def all_clusters
    return @all_clusters if @all_clusters
    @all_clusters = Gexcore::Clusters::Service.get_clusters_in_team_by_user(current_user, current_user.team, "object").data.to_a
  end
  def all_clusters_w_shared
    return @all_clusters_w_shared if @all_clusters_w_shared
    shared_clusters = Gexcore::Shares::Service.get_clusters_share_list_for_user(current_user, "object").data.to_a
    @all_clusters_w_shared = all_clusters + shared_clusters
  end
=begin

  def all_clusters_w_shared
    return @all_clusters_w_shared if @all_clusters_w_shared
    @all_clusters = Gexcore::Clusters::Service.list_clusters_in_team(current_user.team.id)
    @shared_clusters = Gexcore::Shares::Service.list_clusters_share_for_user(current_user)
    @all_clusters_w_shared = @all_clusters + @shared_clusters
  end
=end

  def init_clusters
    all_clusters_w_shared
    init_cluster
  end

  #todo: deprecated
  alias init_current_cluster init_cluster




  def first_not_nil(arr)
    arr.find{|x| !x.nil? }
  end

  def param_first_not_nil(*arr)
    param_name = arr.find{|x| !params[x].nil? }
    params[param_name]
  end


  def to_boolean(str)
    return str if str.in? [true, false]
    str == 'true'
  end



end
