class InternalBaseController < BaseController

  before_action :require_login!

  def require_login!
    return true if validate_token
    render json: { errors: [ { detail: "Access denied" } ] }, status: 401
  end


  private
  def validate_token
    gex_token = Rails.application.secrets.gex_token
    request_token = request.headers['gexToken']
    gex_token == request_token
  end

end
