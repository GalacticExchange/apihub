class SessionsController < Devise::SessionsController
  include AuthCommon

  #prepend_before_action :check_captcha, only: [:create]

  #after_action :after_login, :only => :create

  #respond_to :json
 # layout 'basic'
  layout 'application'


  def after_login
    #
    #my_after_login_callback

  end

  # GET /resource/sign_in
  def new
    @demo=true
    @no_header = true
    @no_footer = true

    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    yield resource if block_given?

    # store location - change 2017-apr-26
    u = params[:from_url] || params[:redirect_to]
    if u
      my_user_store_url_redirect(u)
      #store_location_for(resource, u)
      #x = stored_location_for(resource)
    end



    #
    respond_with(resource, serialize_options(resource))
  end



  # POST /resource/sign_in
  def create

    # remove spaces from the username
    if params['user']['login']
      params['user']['login'].strip!
    end

    self.resource = warden.authenticate!(auth_options)
    #set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)

    yield resource if block_given?

    # generate in session
    my_after_login_callback

    #puts "create: session: #{session['user_url_redirect']}, token: #{session[:token]}"

    # redirect
    u = after_sign_in_path_for(resource)

    #puts "create: u = #{u}"

    # send token back if external link
    uri_redirect  = URI(u) rescue nil
    uri_this = URI(request.original_url)

    is_external = false

    if uri_redirect && uri_redirect.host!=uri_this.host
      is_external = true

      # add token to url
      url_redirect_parsed = Addressable::URI.parse(u)

      s_token = session[:token]

      url_redirect_parsed.query_values = (url_redirect_parsed.query_values || {}).merge({token: s_token})

      u = url_redirect_parsed.to_s

      #puts "create: new u = #{u}"

    end

    #puts "create: final u = #{u}"


    #
    respond_with resource, location: u

  end

  # DELETE /resource/sign_out
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message :notice, :signed_out if signed_out && is_flashing_format?
    cookies.delete :token
    yield if block_given?
    respond_to_on_destroy
  end



  ### original from devise
=begin
  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message(:notice, :signed_in) if is_flashing_format?
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  end
=end

### my with token
=begin
  # POST /resource/sign_in
  # Resets the authentication token each time! Won't allow you to login on two devices
  # at the same time (so does logout).
  def create
    self.resource = warden.authenticate!(auth_options)
    sign_in(resource_name, resource)

    #current_user.update authentication_token: nil

    respond_to do |format|
      format.json {
        render :json => {
                   :user => current_user.to_auth_hash,
                   #:status => :ok,
                   #:authentication_token => current_user.authentication_token
               }
      }
    end
  end
=end

  private
  def check_captcha
    unless verify_recaptcha
      redirect_to root_path and return
      #self.resource = resource_class.new sign_up_params
      #respond_with_navigational(resource) { render :new }
    end
  end



end



