class SysinfoController < BaseController
  def version

    data = {gexcore_version: Gexcore::VERSION}
    render json: data
  end
end
