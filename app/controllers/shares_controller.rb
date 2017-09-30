class SharesController < AccountBaseController
  layout "sidebar_view"
  before_action {@page_selected = "shares"}

  #
  def create
    #
    username = params['username'] || params['new_share']['username'] || ''
    check_current_cluster || return

    admin = current_user

    # work
    res = Gexcore::Shares::Service.create_share_by_admin(admin, @current_cluster, username)

    # log
    gex_logger.log_response(res, 'share_created', "Cluster was shared to :username", 'share_create_error')

    if res.success?
      user = User.get_by_username username
      gex_logger.info("share_created", "You were given an access to cluster of :team_name}")
    end

    #
    respond_to do |format|
      format.html { redirect_to  shares_main_path }
      format.json { return_json(res) }
    end
  end


  # create new share (web page)
  def new
    @share =  ClusterAccess.new
  end


  search_filter :list, {url: :shares_list_path} do
    default_order "id", 'asc'

    field :username, :string, :text, {label: 'Username', default_value: '', condition: :like_full}

  end




  def main

  end



  # share users list in cluster
  # get '/userShares'
  def list_users
    #
    user = current_user
    check_current_cluster || return

    # work
    res = Gexcore::Shares::Service.get_user_shares_list(user, @current_cluster.id)

    ####################### filter
    #
    filter_options = {}
    @filter = SimpleSearchFilter::Filter.new(session, 'shares_', filter_options)

    # define filter
    @filter.set_default_order 'id', 'desc'
    @filter.field 'cluster_id', :int, :text, {label: '', default_value: '', ignore_value: '', condition: :equal}

    @filter.set 'cluster_id', @current_cluster.id
    @items = ClusterAccess.includes(:user).by_filter(@filter)

    return_json(res)
  end




  # share clusters list for user
  # get /clusterShares
  def list_clusters
    #
    user = current_user

    # work
    res = Gexcore::Shares::Service.get_clusters_share_list_for_user(user)

    #return_json(res)
    respond_to do |format|
      format.html  {  }
      format.json { return_json(res) }
    end
  end



  # delete share
  def destroy
    # input
    username = get_param_value("username")

    #
    master_user = User.get_by_username(@username) || current_user  # || ''

    # cluster
    check_current_cluster || return

    # work
    res = Gexcore::Shares::Service.delete_share_by_admin(master_user, @cluster, username)

    # log
    gex_logger.log_response(res, 'share_deleted', "Access to cluster was revoked from :username", 'share_delete_error')

    if res.success?
      user = User.get_by_username username
      gex_logger.info("share_deleted", "You were revoked an access to cluster of :team_name}")
    end

    #
    #return_json(res)

    respond_to do |format|
      format.html  { redirect_to shares_main_path }
      format.json { render json: res }
    end

  end


end
