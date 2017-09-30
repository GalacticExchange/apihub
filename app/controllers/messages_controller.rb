class MessagesController < AccountBaseController
  require 'rails_autolink'

  include MessageHelper

  def create
    #
    @user = current_user


    # input
    if params[:message] && params[:message].kind_of?(Hash)
      to_user_id = params[:message][:to_user_id].to_i
      msg = params[:message][:message]

      @to_user = User.get_by_id to_user_id
    else
      to_username = params['username'] || ''
      msg = params['message'] || ''

      @to_user = User.get_by_username to_username
    end

    #
    if @to_user.nil?
      res = Gexcore::Response.res_error_badinput('','User not found', "user not found")
      return return_json(res)
    end

    if msg.blank?
      res = Gexcore::Response.res_error_badinput('','Message is empty', "message blank")
      return return_json(res)
    end

    # work
    @res = Gexcore::MessagesService.add_message(@user.id, @to_user.id, msg)

    # result
    msg_id = @res.sysdata[:message_id]
    @message = Message.find(msg_id) if msg_id.present?


    # response
    respond_to do |format|
      if @res.success?
        format.html { redirect_to dialog_path(:to => @to_user.username), notice: 'Message was successfully created.' }
        #format.json { render :show, status: :created, location: @message }
        format.json { return_json(@res) }
        format.js   { }
      else
        format.html { render :new }
        #format.json { render json: @message.errors, status: :unprocessable_entity }
        format.json { return_json(@res) }
        format.js   { }
      end
    end
  end




  def new
    @user = current_user

    #
    if @user.nil?
      raise "forbidden"
    end
    # for remote in view/messages/_form_team.html.haml
    @data = false
    @another_user = User.get_by_username(params[:to])
    @message = Message.new
  end


  # GET /posts/1
  # GET /posts/1.json
  def show


  end


=begin
     # DELETE /posts/1
     # DELETE /posts/1.json
    def destroy
      @user = current_user
      @message = Message.find(params[:id])
      @message.destroy
      respond_to do |format|
        format.html { redirect_to dialogsshow_path(:name => current_user.username), notice: 'Message was successfully destroyed.' }
        format.json { head :no_content }
        format.js   { render layout: false }
      end
    end
=end

  def index
    #
    @user = current_user

    # input
    p = {}
    p[:username] = params[:username]


    # work
    res = Gexcore::MessagesService.get_messages(@user.id, p)

    # set messages read
    Gexcore::MessagesService.set_all_messages_read @user.id


    # response
    return_json(res)
  end

  def count_unread
    #
    @user = current_user


    # work
    n = Gexcore::MessagesService.get_unread_count_user(@user.id)

    res = Gexcore::Response.res_data({count: n})

    # response
    return_json(res)
  end





  private

  def messages_params
    params.require(:message).permit(:from_user_id, :to_user_id, :id, :dialog_id, :status, :message)
  end

end
