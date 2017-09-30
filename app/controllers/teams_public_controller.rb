class TeamsPublicController < BaseController
  autocomplete :team, :name

  ### search
  def search
    # input
    q = params['q'] || ''

    if q.nil? || q.blank?
      res = Gexcore::Response.res_error_badinput('', 'No input')
      return return_json(res)
    end

    # work
    res = Gexcore::TeamsSearchService.search(params, session)

    return_json(res)
  end



  def show
    #@user = current_user

    name = params[:name]
    @view = params[:view] || 'members'

    if name
      @team = Team.get_by_name(name)
    end

    @users = User.where(:team_id => @team).order("id desc")
    @clusters = Cluster.where(:team_id => @team).w_not_deleted.order("id desc").all
  end

end


