class LogController < AccountBaseController
#class LogController < BaseController
  layout "sidebar_view"
  before_action {@page_selected = "logs"}

  def index
    user = current_user

    # check permissions
    return Gexcore::Response.res_error_forbidden('forbidden', 'No permissions to view log') unless user.can?(:view_log, user.team)

    #
    @filter = Gexcore::LogService.create_filter_from_params(params, session, {save_session: false})


    if params['filter_cmd'] == "clear"
      @filter.clear_all
      redirect_to logs_path
    end

    # for view
    source_id = @filter.v('source_id')
    source = LogSource.find source_id if source_id > 0
    @filter.set 'source', source.name if source

    user_id = @filter.v('user_id')
    user1 = User.find user_id if user_id > 0
    @filter.set 'user', user1.username if user1

    node_id = @filter.v('node_id')
    node = Node.w_not_deleted.where(id: node_id).first if node_id > 0
    #node = Node.find node_id if node_id > 0
    @filter.set 'node', node.name if node

    @min_lvl = @filter.v('min_level')
    @options_levels = Gexcore::LogLevel.get_all

    # team
    team = user.team
    @filter.set 'team_id', team.id

    # visible_client
    @filter.set 'visible_client', 1

    # cluster
    check_current_cluster || return
    @filter.set 'cluster_id', @current_cluster.id

    #
    page_num = params[:pg].to_i
    #
    Gexcore::LogDebugSearchService.set_date_and_pagin_filter(@filter, page_num)
    # get
    @total, @records = Gexcore::LogDebugSearchService.search_by_filter(@filter)

    @res = @records.empty? ? Gexcore::Response.res_data {} : Gexcore::Response.res_data(Gexcore::LogDebugSearchService.to_hash(@records, @total))#, @filter))
    #@res = @records.empty? ? Gexcore::Response.res_data {} : @records

    #
    #res = Gexcore::LogService.search_by_user(user, params, session)

    #
    respond_to do |format|
      format.html {      }
      format.json { return_json(@res) }
    end
  end

end
