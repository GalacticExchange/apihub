module AuthCommon
  extend ActiveSupport::Concern

  included do

  end

  ### callbacks
  def my_after_login_callback(token=nil)
    if token.nil?
      token = Gexcore::AuthService.jwt_generate current_user
      session[:token] = token

    end

    set_cookies_token

    # update data
    Gexcore::ClustersAccessService.redis_update_clusters_access(current_user)

  end

  def handle_sign_in_via_rememberable
    if current_user && current_user.signed_in_via_remember?
      current_user.update_attribute(:signed_in_via_remember, false)
      my_after_login_callback
      after_sign_in_path_for(User)
    end


  end



  ### devise

  def after_sign_in_path_for(resource)
    sign_in_url = new_user_session_url


    uri_referer = nil

    #if uri_referer.host==uri_signin.host && uri_referer.path==uri_signin.path &&
    #    uri_referer.port==uri_signin.port
    #if request.referer
    #  uri_referer = URI(request.referer) rescue nil
    #  uri_signin = URI(sign_in_url)
    #end

    if request.referer == sign_in_url || request.referer == request.original_url
      super
    else
      #u = stored_location_for(resource) || request.referer || root_path
      u = my_user_stored_url_redirect || request.referer || root_path


      u
    end
  end

  ### devise
  def store_current_location
    #if params[:from_url]
    #  store_location_for(:user, params[:from_url])
    #end

    # default
    #store_location_for(:user, request.url)
  end


  def my_user_store_url_redirect(u)
    session['user_url_redirect'] = u
  end

  def my_user_stored_url_redirect(v_def=nil)
    session['user_url_redirect'] || v_def
  end



  ### cookies
  def set_cookies_token
    # set cookies from session
    cookies[:token] = session[:token]
    #cookies[:token] = {:value=> session[:token], :expires => 1.month.from_now}

  end
end
