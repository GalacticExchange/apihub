class PingController < BaseController

  def ping
    render json: {pong: 'pong', time: Time.now.utc.to_s}
  end
end
