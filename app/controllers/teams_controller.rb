class TeamsController < AccountBaseController

  ###
  def show_info
    # username
    @user = current_user

    # work
    res = Gexcore::TeamsService.get_team_info(@user.team_id)

    return_json(res)
  end


  ### put
  def update
    #
    fields_data = Gexcore::TeamsService.get_fields_data_from_params(params)

    # work
    user = current_user
    team = user.team

    res = Gexcore::TeamsService.update_team_info_by_user(user, team, fields_data)

    gex_logger.log_response(res, 'team_info_updated', 'team info was updated', 'team_info_update_error')

    return_json(res)
  end

  def group_list
    groups = Group.all.map(&:to_hash) #.pluck(:id, :name, :title)

    res = Gexcore::Response.res_data({groups: groups})

    return_json(res)
  end


end


