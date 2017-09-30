class Admin::UsersController < Admin::MyAdminBaseController

  #autocomplete :user, :username, :full => true

  def autocomplete_user_username

    q = params[:q]

    items = Gexcore::ElasticSearchHelpers.autocomplete_elastic_dsl_array_for_render_json(q.downcase, "User", ["username"])

    #
    #render :json => Gexcore::Common.items_to_json(items, 'id', 'username')
    render :json => items

  end

  # search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_users_url, search_url: :search_admin_users_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :status, :int, :select, {
                     label: 'Status',
                     default_value: -1, ignore_value: -1,
                     collection: User.for_filter_statuses
                 }

    field :team, :string, :autocomplete, {label: 'Team', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_team_name_admin_teams_path, input_html: {style: "width: 180px"}}

    field :username, :string, :text, {label: 'username', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}
    field :email, :string, :text, {label: 'email', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}
  end

  def show
    id = params[:id]
    if id.nil?
      raise 'Bad input'
    end

    @user = User.find id
    @yt_user = @user.yt_info
  end

  def index
    @team_id = params[:team_id]

    if @team_id
      @team = Team.find(@team_id)
      @filter.set 'team_id', @team_id
      @filter.set 'team', @team.name
    end

    @items = User.includes(:team).by_filter(@filter)
    #user_ids = User.pluck(:id)

    user_ids = @items.map(&:id)

    @invitations_count = Invitation.where(:from_user_id => user_ids).group(:from_user_id).count

    #MyTestWorker.perform_async('testttt12')

  end

  def get_token

    @user = User.find(params[:id])

    #
    @token = Gexcore::AuthService.jwt_generate @user

    # response
    @res = Gexcore::Response.res_data({token: @token})

    respond_to do |format|
      format.html {      }
      format.json{        return_json(@res)      }
    end
  end

###
  def new

    @user = User.new
    @user.build_team
    @cluster_hadoop_types = ClusterHadoopType.order(:name)

  end

  def create
    @cluster_hadoop_types = ClusterHadoopType.order(:name)

    # input
    p = params[:user].present? ? params[:user] : params

    @sysinfo = {}
    @registration_options = {}

    if params[:user]
      @registration_options[:hadoop_type] = params[:user][:cluster_hadoop_types][:name]
    end

    @user = Gexcore::UsersCreationService.build_user_from_params(p, true)

    #@res = Gexcore::UsersCreationService.create_user_active(@user, @sysinfo)
    @res = Gexcore::UsersCreationService.create_user_by_phone(@user, @sysinfo, @registration_options, true, true)

    # log
    gex_logger.log_response(@res, 'user_created', "User was created. Username: :username", 'user_create_error')

    respond_to do |format|
      if @res.success?
        format.html {
          #redirect_to @user, notice: 'User was successfully created.'
          redirect_to admin_users_path, notice: 'User was successfully created.'
        }
        format.json {
          #render :show, status: :created, location: @user
          return_json(@res)
        }
      else
        format.html {
          render :new
        }
        format.json {
          #render json: @user.errors, status: :unprocessable_entity
          return_json(@res)
        }
      end
    end
  end

  def edit_status
    @user = User.find (params[:id]) if params[:id]
  end

  def update_status
    @user = User.find (params[:id]) if params[:id]

    @res = @user.update(status_params)
    respond_to do |format|
      if @res
        format.html {
          redirect_to admin_user_path(@user)
        }
        #format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :show }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit_notes
    @user = User.find (params[:id]) if params[:id]
  end

  def update_notes
    #@user = User.find (session[:id]) if session[:id]
    @user = User.find (params[:id]) if params[:id]

    @res = @user.update(note_params)
    respond_to do |format|
      if @res
        format.html {
          redirect_to admin_user_path(@user)
        }
        #format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :show }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def show_nodes_perf
    #
    @user = User.find(params[:id])

    # token
    @token = Gexcore::AuthService.get_new_token @user

    # redirect
    redirect_to '/nodes/performance/?token='+@token
  end
=begin
  def update_password_from_admin
    #
    pwd = params[:newPassword]
    victim_username = params[:username]

    victim = User.get_by_username victim_username

    victim.password = pwd
    victim.password_confirmation = pwd
    res_user = victim.save
    respond_to do |format|
      if res_user
        format.html {
          redirect_to admin_user_path(@user)
        }
        #format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :show }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
=end
# reset password
  def editpassword_from_admin
    @user = User.find (params[:id]) if params[:id]
  end

  def updatepassword_from_admin
    pwd = params[:user][:password]
    #
    @user = User.find (params[:id]) if params[:id]

    #
    @res = Gexcore::UsersService.set_password_from_adminarea(@user, pwd)

    # log
    @resp = @res ? Gexcore::Response.res_data : Gexcore::Response.res_error("user_password_update_error", "Cannot change password")

    gex_logger.log_response(@resp, 'user_password_updated', 'Password was changed', 'user_password_update_error')

    #
    respond_to do |format|
      if @res
        format.html {
          redirect_to admin_user_path @user, notice: 'Password was successfully changed.'
        }
      else
        format.html {
          render :editpassword_from_admin
        }
      end
    end
  end

  def login_as_user
    sign_in(:user, User.get_by_username(params[:username]))
    redirect_to root_path
  end

  def verify_user
    @user = User.get_by_username(params[:username])

    @res = Gexcore::UsersCreationService.verify_user_by_admin(@user) if @user

    # log
    gex_logger.log_response(@res, 'user_verify', "User was verified. Username: #{params[:username]}", 'user_verify_error')

    respond_to do |format|
      if @res.success?
        format.html {
          redirect_to admin_users_path, notice: 'User was successfully verified.'
        }
        format.json {
          return_json(@res)
        }
      else
        format.html {
          render :show, notice: 'User not verified.'
        }
        format.json {
          return_json(@res)
        }
      end
    end
  end


  def generate
    # input
    username = params[:username]


    opts = {}
    @user = Gexcore::UsersCreationService.generate_random_user(opts)
    @res = true

    respond_to do |format|
      if @res
        format.json { return_json_data(@user.to_hash_admin) }
      else
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def status_params
    params.require(:user).permit(:status)
  end

  def note_params
    params.require(:user).permit(:admin_notes)
  end

  def user_password_params
    params.require(:user).permit( :password, :password_confirmation)
  end

end
