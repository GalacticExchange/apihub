class NodesAgentController < BaseController

  before_action :auth_node_agent

  def auth_node_agent
    # authorize request
    init_auth_data

    if @res_auth.error?
      return (return_json @res_auth)
    end
  end

  def update
    # input
    @node_uid = get_node_uid


    @data = {
        instance_uid: params[:instanceID],
        host_type: params[:hostType],
        options: params[:options]
    }

    #
    res = Gexcore::Nodes::Service.update_node(@node_uid, @data)

    return_json(res)
  end


  private

  def get_node_uid
    get_param_value(:nodeID) || get_param_value(:id) || ''
  end

  def init_node_uid
    @node_uid = get_node_uid
  end

end
