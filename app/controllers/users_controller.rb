class UsersController < BaseController
  layout 'basic'

  before_action :authorize_request, only: [:update, :destroy, :update_role, :show_info, :list_of_team, :autocomplete_user_username]
      #[:new, :create, :verify, :search,  :update_password, :send_password_resetlink, :show]
  before_action :init_current_cluster , only: [:autocomplete_user_username]

  #prepend_before_action :check_captcha, only: [:create]

  #before_action :set_user, only: [:show, :edit, :update, :destroy]
  #autocomplete :user, :username#, {:full => true, :column_name=>'username'}


  # autocomplete
  def autocomplete_user_username

    check_current_cluster || return

    #
    q = params[:q]

    is_full_search = nil
    like_clause = 'LIKE'

    model = User.w_not_deleted.where(team_id: current_user.team_id)
    items = model.where(["LOWER(#{'users'}.#{'username'}) #{like_clause} ?", "#{(is_full_search ? '%' : '')}#{q.downcase}%"]).limit(10).order("id asc")

    render :json => Gexcore::Common.items_to_json(items, 'id', 'username')
  end



  ###
  def new
    #
    @no_header = true

    # input
    @invitation_token = params[:invitationToken] || params[:shareToken] || params[:invitation_token] || ''
    email = params[:email]

    #
    @invitation = Gexcore::InvitationsService.find_not_activated_invitation_by_token(@invitation_token)
    if !@invitation_token.blank? && @invitation.nil?
      render :accept_error and return
    end

    @user = User.new
    @user.email = email if email

    @user.build_team

    if @invitation
      team = Team.find(@invitation.team_id)

      @user.email = @invitation.to_email
      #@user.token = @invitation.uid

      if @invitation.invitation_type == Invitation::TYPE_MEMBER
        @user.team.name = team.name
      elsif @invitation.invitation_type == Invitation::TYPE_SHARE
        # do nothing
      end
    end

  end


  def edit
    raise 'not supported'
  end



  def create
    # input
    @invitation_token = params[:invitation_token] || params[:token] || ''
    @sysinfo = params[:systemInfo] || {}

    # input
    p = params[:user].present? ? params[:user] : params
    p[:registration_ip] = request.remote_ip
    @user = Gexcore::UsersCreationService.build_user_from_params p

    # enterprise
    #@is_enterprise = (params[:enterprise] || 0).to_i == 1
    @registration_options = build_registration_options_from_params()

    gex_logger.debug('debug_create', "params", {p: "#{params.inspect}"})

    #
    if !Gexcore::UsersCreationService.is_test_mode_registration(@user)
      # captcha
      unless verify_recaptcha
        @res = Gexcore::Response.res_error('', 'Bad captcha', "Bad captcha", 400)
        respond_to do |format|
          format.html {
            @no_header = true
            render :new and return
          }
          format.json { return_json(@res) and return }
        end
      end
    end

    #
    @invitation = Gexcore::InvitationsService.find_not_activated_invitation_by_token(@invitation_token)

    #
    is_test_mode = Gexcore::UsersCreationService.is_test_mode_registration(@user)
    if !@invitation_token.nil? && !@invitation_token.blank?
      @res = Gexcore::UsersCreationService.create_user_with_invitation_token(@invitation_token, @user, @sysinfo, false, is_test_mode)
    else
      #@res = Gexcore::UsersCreationService.create_user_not_verified(@user, @sysinfo, @registration_options)
      @res = Gexcore::UsersCreationService.create_user_by_phone(@user, @sysinfo, @registration_options, false, is_test_mode)
    end

    # log
    gex_logger.log_response(@res, 'user_created', "User was created. Username: :username", 'user_create_error')

    #slack
    Gexcore::Log::Slack.user_created(@user) if @res.success?

    respond_to do |format|
      if @res.success?
        @need_verification = @invitation_token.blank? ? 1 : 0

        format.html {
          #redirect_to @user, notice: 'User was successfully created.'
          redirect_to user_result_created_path(need_verification: @need_verification), notice: 'User was successfully created.'
        }
        format.json {
          #render :show, status: :created, location: @user
          return_json(@res)
        }
      else
        format.html {
          @no_header = true
          render :new
        }
        format.json {
          #render json: @user.errors, status: :unprocessable_entity
          return_json(@res)
        }
      end
    end
  end

  def build_registration_options_from_params
    res = {}

    # not used. moved to cluster options // 2017-01-20


    res
  end



  def verify
    # input
    @token = params['verificationToken'] || params[:token] || ''

    # check token
    if !(@token=~ /^[a-z0-9]+$/)
      @res = Gexcore::Response.res_error('', 'bad data', "bad token", 400)

      respond_to do |format|
        format.html {          render 'users/verify_error' and return        }
        format.json {          return_json(@res)     and return   }
      end
    end


    # do the job
    @res = Gexcore::UsersCreationService.verify_user_by_token(@token)

    # log
    gex_logger.log_response(@res, 'user_verified', "Email was verified: :email", 'user_verify_error')


    respond_to do |format|
      if @res.success?
        format.html {          redirect_to user_result_verified_path   and return     }
        format.json { return_json(@res)  and return}
      else
        format.html {          render 'users/verify_error' and return        }
        format.json { return_json(@res)  and return}
      end
    end

  end




  ### put
  def update
    #
    fields_data = Gexcore::UsersService.get_fields_data_from_params(params)

    # work
    user = current_user

    res = Gexcore::UsersService.update_user_info(user.username, fields_data)

    gex_logger.log_response(res, 'user_info_updated', 'User info was updated', 'user_info_update_error')

    return_json(res)
  end


=begin
  def update
    raise 'not supported'

    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
=end




  # delete user
  def destroy
    # input
    username = get_param_value("username")

    # work
    res = Gexcore::UsersService.delete_user_by_admin(username, current_user)

    # log
    gex_logger.log_response(res, 'user_deleted', "User :username was deleted", 'user_delete_error')

    #
    return_json(res)
  end



  # update password
  def update_password
    # input
    password_token = params[:passwordToken]

    # auth token
    init_auth_data

    # auth request
    if @res_auth.error? && password_token.nil?
      return (return_json @res_auth)
    end

    # request by passwordToken
    if @res_auth.error? && password_token
      # change pwd by token + new pwd

      # input
      #token = params['passwordToken']
      password = params['newPassword']

      #
      res = Gexcore::UsersService.set_password_by_token(password_token, password)

      # log
      gex_logger.log_response(res, 'user_password_updated', 'Password was changed', 'user_password_update_error')

    else
      # update for auth request
      oldpwd = params[:oldPassword]
      pwd    = params[:newPassword]
      devise_params = {:current_password => oldpwd, :password => pwd, :password_confirmation => pwd}
      #
      @admin_user = current_user

      victim_username = params[:username]

      # work
      if victim_username
        res = Gexcore::UsersService.set_password_by_admin(@admin_user, victim_username, pwd)
      else

        #
        res = Gexcore::Response.new
        result = @admin_user.update_with_password(devise_params)

        if result
          bypass_sign_in(@admin_user)
          res.set_data
          # log
          gex_logger.log_response(res, 'user_password_updated', 'Password was changed', 'user_password_update_error', {user_id: @admin_user.id})
        else
          res.set_error('update_fails', 'Password update fails', nil, 401)
        end

      end
    end

    return_json(res)
  end



  # change user role
  def update_role
    # input
    username = params['username'] || ''
    role = params['role'] || ''

    #
    admin = current_user

    # work
    res = Gexcore::UsersService.set_role_by_admin(admin, admin.team, username, role)

    #
    gex_logger.log_response(res, 'user_role_updated', "User role was changed. User :username", 'user_role_update_error')

    #
    return_json(res)
  end


  # users password reset
  def send_password_resetlink
    # input
    username = params['username']

    # work
    res = Gexcore::UsersService.send_resetpassword_link(username)

    return_json(res)
  end


  def show

    username = params[:name]

    if username
      @user = User.get_by_username(username)
    end

    @main_user = current_user
    @clusters = Cluster.where(:team_id => @user.team_id).w_not_deleted.order("id desc").all
  end



  def show_info
    # username
    username = params['username'] || current_user.username

    # work
    res = Gexcore::UsersService.get_user_info(username)

    return_json(res)
  end


  ### search users
  def search
    # username
    q = params['q'] || ''

    if q.nil? || q.blank?
      res = Response.res_error_badinput('', 'No input')
      return return_json(res)
    end

    # work
    res = Gexcore::UsersSearchService.search(params, session)

    return_json(res)
  end


  # users team list
  def list_of_team
    #
    user = current_user


    # work
    res = Gexcore::UsersService.get_users_in_team(user)

    return_json(res)
  end



  # thank you page after reset password link is sent
  def result_resetpwdlink_sent

  end



  def result_created
    p_verify = params[:need_verification] || 0
    @need_verify = p_verify.to_i == 1


  end


  def result_verified

  end




  # thank you page after password was reset
  def result_password_changed


  end

  # bad token page
  def bad_token

  end



  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_password_params
    #params.require(:user).permit(:password, :password_confirmation)
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end


  def user_params
    params.require(:user).permit(:username, :email, :firstname, :lastname, :password, :password_confirmation, :avatar,
      :team_attributes=>[:name])
    #:team=>[:name]
  end


  ###


end
