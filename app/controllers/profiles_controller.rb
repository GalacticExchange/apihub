class ProfilesController < AccountBaseController
  #layout 'basic'
  #layout 'application'
  layout 'sidebar_view'

  before_action :set_user_set_team
  before_action {@page_type = "profile"}


  def show
    @t = params[:type]
    @view = params[:view] || 'profile'

    if @view == "profile"
      @profile = true
    elsif @view == "clusters"
      @clusters = true
    end

    @my_clusters = Gexcore::Clusters::Service.list_clusters_in_team(@user.team.id) # TODO shared clusters list

  end


  def edit

    @page_selected = "profile_edit"
    @t = params[:type]
  end




  def update

    data = user_params_for_profile
    @res = Gexcore::UsersService.update_user_info(@user.username, data)

    #gex_logger.log_response(@res, 'user_info_updated', 'User info was updated', 'user_info_update_error', @user.username)

    respond_to do |format|
      if @res
        format.html {
          redirect_to NgRoutes::PROFILE_EDIT.gsub('{username}', current_user.username), notice: 'User was successfully updated'
        }
        #format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # reset password
  def editpassword
    @page_selected = "profile_edit_password"
  end

  def updatepassword
    #
    @res = @user.update_with_password(user_password_params)
    #@res = Gexcore::UsersService.update_user_password(@user.username, oldpwd, pwd)

    # log
    @resp = @res ? Gexcore::Response.res_data : Gexcore::Response.res_error("user_password_update_error", "Cannot change password")

    gex_logger.log_response(@resp, 'user_password_updated', 'Password was changed', 'user_password_update_error')

    #
    respond_to do |format|
      if @res
        sign_in @user, :bypass => true
        format.html {
          redirect_to NgRoutes::PROFILE_EDIT.gsub('{username}', @user.username), notice: 'Password was successfully changed.'
        }
        #format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :editpassword }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit_avatar
    @page_selected = "profile_edit_avatar"
  end

  def update_avatar
    avatar_params = user_params_for_avatar
    @res = @user.update(avatar_params)


    respond_to do |format|
      if @res
        #format.json { render json:  {"url" => "?????","user_id" => "???",}}
        format.json {render json: {"res"=>"1","url"=>"#{@user.avatar.url(:medium)}"}}
        #format.json { @res }
        format.html {
          redirect_to uploads_path, notice: 'Avatar was successfully updated'
        }
        #format.json { render :show, status: :ok, location: @user }
      else
        format.json {render json: { "res"=>"0","url"=>""}}
        #format.html { render :edit }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end


  ### for team
  # GET /team/edit/:name
  def show_team
    @clusters = Gexcore::Clusters::Service.list_clusters_in_team(@user.team.id)
    @users = User.w_not_deleted.where(:team_id => @team_id).order("id ASC").all
  end

  def edit_team
    @page_selected = "profile_team_edit"
    unless @user.can?(:change_team, @user.team)
      raise "forbidden"
    end
  end

  def update_team
    #
    unless @user.can?(:change_team, @user.team)
      raise "forbidden"
    end

    #@team = Team.find(@user.team_id)
    data = team_params
    @res = Gexcore::TeamsService.update_team_info(@user.team, data)

    #gex_logger.log_response(@res, 'team_info_updated', 'Team info was updated', 'team_info_update_error', @team.name)

    respond_to do |format|
      if @res
        format.html {
          redirect_to NgRoutes::TEAM_EDIT, notice: t('teams.updated')
        }
        #format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit_avatar_team
    unless @user.can?(:change_team, @user.team)
      raise "forbidden"
    end
  end

  def update_avatar_team

    avatar = team_params_for_avatar
    @res = @team.update(avatar)

    respond_to do |format|
      if @res
        format.json {render json: {"res"=>"1","url"=>"#{@team.avatar.url(:medium)}"}}
        #format.html {
        #  redirect_to team_show_path, notice: 'Avatar was successfully updated'
        #}
        #format.json { render :show, status: :ok, location: @user }
      else
        format.json {render json: { "res"=>"0","url"=>""}}
        #format.html { render :edit }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

# for team

  def team_members

    @page_selected = "profile_team_members"
    a = Gexcore::UsersService.get_users_in_team(@user, "object")
    @items = a.data


    respond_to do |format|
      format.json {

        @items = @items.as_json

        # todo: tmp fx - pack avatar_url and teamname to user hash
        @items.map do |n|
          tmp_user = User.get_by_username(n['username'])
          n[:avatar_url] = ApplicationController.helpers.avatar_url(tmp_user, :thumb)
          n[:team_name] = tmp_user.team.name

          group = Group.find(tmp_user.group_id)
          n[:group_name] = group.name
          n[:group_title] = group.title
        end

        render json: @items
      }
      format.html{        }
    end
  end

  def team_inv
    @page_selected = "profile_team_invitations"
    a = Gexcore::InvitationsService.get_invitations_in_team(@user, @user.team_id, "object")
    @items = a.data

    respond_to do |format|
        format.json {          render json: @items        }
        format.html{        }
    end
  end





# for cluster

  def my_clusters
    a = Gexcore::Clusters::Service.get_clusters_in_team_by_user(@user, @user.team, "object")
    @items = a.data
  end

  def shared_clusters
    a = Gexcore::Shares::Service.get_clusters_share_list_for_user(@user, "object")
    @items = a.data
  end

  def cluster_all
    # my clusters list
    my_clusters = Gexcore::Clusters::Service.get_clusters_in_team_by_user(@user, @user.team, "object")
    @my_clusters = my_clusters.data

    # my shared clusters list
    shared_clusters = Gexcore::Shares::Service.get_clusters_share_list_for_user(@user, "object")
    @shared_clusters = shared_clusters.data
  end

  def show_cluster
    @name = params[:name]

    @cluster = Cluster.get_by_name(@name)
    @nodes_count = Node.where(:cluster_id => @cluster).count
  end

  def show_shared_cluster
    @name = params[:name]

    @cluster = Cluster.get_by_name(@name)
    @nodes_count = Node.where(:cluster_id => @cluster).count
  end



  private

  def set_user_set_team
    @user = current_user
    @team = @user.team
  end

  def user_password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end

  def user_params_for_profile
    params.require(:user).permit(:firstname, :lastname, :about)
  end

  def user_params_for_avatar
    params.require(:user).permit(:avatar)
  end

  def team_params
    params.require(:team).permit(:about)
  end

  def team_params_for_avatar
    params.require(:team).permit(:avatar)
  end
end
