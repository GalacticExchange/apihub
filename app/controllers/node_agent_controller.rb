class NodeAgentController < BaseController

  before_action :init_data


  def init_data
    # authorize request
    init_auth_data

    #
    @node_id = @res_auth.data[:agent_node_id]

    if @node_id.present?
      @node = Node.get_by_id @node_id
    end

    # cluster
    init_current_cluster

    if @node
      @cluster = @node.cluster
    else
      @cluster = @current_cluster
    end

  end

  ### Agent

  def update_agent_info
    # input
    data = {
        ip: params[:ip],
        port: params[:port],
    }

    # work
    @res = Gexcore::Nodes::AgentService.update_info_by_agent(@node_id, data)

    return_json(@res)
  end

  def get_agent_info
    # node
    if @node.nil?
      @node = Node.get_by_uid(params[:nodeID])
    end


    # work
    @res = Gexcore::Nodes::AgentService.get_agent_info(@node)

    return_json(@res)
  end


  def get_agents
    # work
    @res = Gexcore::Nodes::AgentService.get_agents(@cluster)

    return_json(@res)
  end


  private


end

