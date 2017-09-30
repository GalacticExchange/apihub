class ApiDialogsController < BaseController

  ### API get '/messagedialogs'
  def list
    #
    @user = User.get_by_username @username


    # work
    res = Gexcore::MessagesService.get_dialogs_for_user(@user.id)

    # response
    return_json(res)
  end


  ### API get '/messagedialogInfo'
  def show_info
    #
    @user = User.get_by_username @username

    to_username = params['username'] || ''
    @to_user = User.get_by_username to_username

    # work
    res = Gexcore::MessagesService.get_dialog_info_for_user(@user, @to_user)

    # response
    return_json(res)
  end



end
