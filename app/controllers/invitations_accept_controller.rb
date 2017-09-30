class InvitationsAcceptController < BaseController
  layout "sidebar_view"

  def validate
    # input
    token = params[:token] || ''

    # do the job
    # validate token
    @res = Gexcore::InvitationsService.validate_token(token)

    return_json(@res)
  end


  def accept
    @token = params[:token] || ''

    # check token
    if !(@token=~ /^[a-z0-9]+$/)
      @res = Gexcore::Response.res_error('', 'bad data', "bad token: #{@token}", 400)
      render :accept_error and return
    end

    # validate
    res_validate = Gexcore::InvitationsService.validate_token(@token)

    if res_validate.success?
      redirect_to '/users/new?invitationToken='+@token
    else
      @res = res_validate
      render :accept_error and return
    end

  end

end
