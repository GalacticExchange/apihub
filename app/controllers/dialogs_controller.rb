class DialogsController < AccountBaseController
  #before_action :set_user, only: [:show, :edit, :update, :destroy]

  before_action {@page_type = "messages"}

  def init_dialogs

    @dialogs = Gexcore::MessagesService.list_dialogs_for_user(@user.id)
    @not_read_dialogs = {}

    @dialogs.each do |t|
      @not_read_dialogs[t.id] = Gexcore::MessagesService.get_unread_count_in_dialog(@user.id, t.id)
    end

  end

  def index
    init_dialogs
    if @dialogs.to_a.length > 0
      user = @dialogs[0].from_user_id == @user.id ?   @dialogs[0].to_user :  @dialogs[0].from_user
      @user = current_user
      redirect_to dialog_path(:to => user.username)
    end


  end


  # GET /users/1
  # GET /users/1.json
  def show
    # for remote in view/messages/_form_team.html.haml
    @data = true
    #
    @user = current_user
    @another_user_name = params[:to] || ''
    @another_user = User.get_by_username @another_user_name
    @usss = @another_user

    #
    #@dialog = Gexcore::MessagesService.get_dialog_by_users(@user.id, @another_user.id)
    @dialog = MessageDialog.find_or_create_by_users(@user.id, @another_user.id)

    @messages = Gexcore::MessagesService.get_messages_in_dialog(@user.id, @dialog.id)


    @message = Message.new

    init_dialogs
  end

  # GET /users/1/edit
  def edit
    @t = params[:type]
    @user = current_user
  end

  def update
    @user = current_user

    data = user_params_for_profile
    #@res = @user.update(data)
    @res = Gexcore::UsersService.update_user_info(@user.username, data)

    gex_logger.log_response(@res, 'user_info_updated', 'User info was updated', 'user_info_update_error', @user.username)

    respond_to do |format|
      if @res
        format.html {
          redirect_to NgRoutes::PROFILE_EDIT.gsub('{username}', @user.username), notice: 'User was successfully updated'
        }
        #format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end



  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def dialogs_params
    params.require(:dialog).permit(:from_user_id, :to_user_id, :id)
  end
end
