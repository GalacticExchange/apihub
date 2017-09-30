class AccountBaseController < BaseController
  #include AuthCommon

  before_action :set_headers

  protected
  def set_headers
    response.headers['Vary'] = 'Accept'
  end

  ###

  before_action :handle_sign_in_via_rememberable

  before_action :authorize_request
  #before_action :_user_logged_in
  before_action :set_common_data


  ###


  def set_common_data
    @page_selected = ''

    # fix token in cookies
    if cookies[:token].nil? && !session[:token].nil?
      set_cookies_token
    end

    @user = current_user

    if @user
      @team = @user.team
      unless json_request?
        init_clusters
        init_cluster_permissions
        init_top_apps_list if @current_cluster
        count_unread_messages
      end

    end
  end

  def init_cluster_permissions
    if @current_cluster
      @permissions[:cluster_manage] = true   if current_user.can? :manage, @current_cluster
      @permissions[:logs] = true             if current_user.can? :view_cluster_logs, @current_cluster
      @permissions[:shares] = true           if current_user.can? :shares_list, @current_cluster
    else
      set_def_permissions
    end
  end


  def check_cluster_exist
    if @current_cluster.nil? && @page_selected !="no_cluster"
      redirect_to no_cluster_path and return
    end
  end

  def count_unread_messages
    @unread_count = Gexcore::MessagesService.get_unread_count_user(current_user.id)
  end

  def init_top_apps_list
    @apps_top = @current_cluster.applications.w_not_deleted.order('id asc').offset(1).limit(5)
  end

end
