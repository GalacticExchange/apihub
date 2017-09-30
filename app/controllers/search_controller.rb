class SearchController < AccountBaseController
  layout 'search'

  def index
    @page_with_def_search = true
  end

  def search_counts
    # users
    filter_users = Gexcore::UsersSearchService.create_filter_from_params(params, session)
    total_users = Gexcore::UsersSearchService.search_total_by_filter(filter_users)

    # teams
    filter_teams = Gexcore::TeamsSearchService.create_filter_from_params(params, session)
    total_teams = Gexcore::TeamsSearchService.search_total_by_filter(filter_teams)

    # clusters
    filter_clusters = Gexcore::ClustersSearchService.create_filter_from_params(params, session)
    total_clusters = Gexcore::ClustersSearchService.search_total_by_filter(filter_clusters)

    res = Gexcore::Response.res_data({counters: {usersCount: total_users, teamsCount: total_teams, clustersCount: total_clusters}})

    return_json(res)
  end

end
