class InvitationsController < AccountBaseController
  #layout "sidebar_view"

  def create
    # input
    victim_email = params[:email] || ''

    # data
    user = current_user

    # work
    res = Gexcore::InvitationsService.send_invitation(user.team_id, victim_email, user)

    # log
    gex_logger.log_response(res, 'invitation_sent', "Invitation was sent to :email", 'invitation_send_error', {user_id: user.id})


    # response
    return_json(res)
  end

  # send share invitation
  def create_share
    # input
    email = params[:email] || ''

    check_current_cluster || return

    admin = current_user

    # work
    res = Gexcore::InvitationsService.send_share_invitation(admin, email, @current_cluster.id)

    # log
    gex_logger.log_response(res,
                            'share_invitation_sent',
                            "Invitation to share cluster was sent to :email",
                            'share_invitation_send_error',
                            {user_id: admin.id}
    )

    #
    return_json(res)
  end







  # invitations list
  def index
    #
    user = current_user


    # work
    res = Gexcore::InvitationsService.get_invitations_in_team(user, user.team_id)

    return_json(res)
  end

  # share_invitations list /shareInvitations
  def index_share
    @page_selected = "shares"
    check_current_cluster || return

    # work
    res = Gexcore::InvitationsService.get_share_invitations_in_cluster(current_user, @current_cluster.id)

    respond_to do |format|
      format.html  {  }
      format.json { return_json(res) }
    end
  end

  # delete invitation
  def destroy
    #
    invitation_id = get_param_value("id")

    #
    master_user = current_user

    # work
    res = Gexcore::InvitationsService.delete_invitation(master_user, invitation_id)

    # log
    gex_logger.log_response(res,
                            'invitation_deleted',
                            "Invitation was deleted. Email: :to_email",
                            'invitation_delete_error',
                            {user_id: master_user.id}
    )


    respond_to do |format|
      format.html  {
        redirect_to shares_main_path(:selected=>"2")
      }
      format.json { render json: res }
    end
  end



end
