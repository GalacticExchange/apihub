module Gexcore::Nodes


  class AgentService < Gexcore::BaseService

    def self.update_info_by_agent(node_id, data)
      res = Response.new
      res.sysdata[:node_id] = node_id

      node = Node.get_by_id node_id

      return res.set_error_badinput("", 'node not found', "node not found") if node.nil?

      # update in DB
      node.ip = data[:ip]
      node.agent_port = data[:port]

      res_db = node.save

      return res.set_error_badinput("", 'Cannot update node', "Error updating node data in DB") if !res_db



      res.set_data
    end

    def self.get_agent_info(node)
      res = Response.new
      res.sysdata[:node_id] = node.id

      return res.set_error_badinput("", 'node not found', "node not found") if node.nil?

      #
      res.set_data({agent: node.to_hash_agent})
    end

    def self.get_agents(cluster)
      res = Response.new

      return res.set_error_badinput("", 'Cluster is empty', "Cluster is nil") if cluster.nil?

      #res.sysdata[:node_id] = agent_node_id
      res.sysdata[:cluster_id] = cluster.id

      #node = Node.get_by_id agent_node_id
      #return res.set_error_badinput("", 'node not found', "node not found") if node.nil?

      #
      nodes = cluster.nodes.w_joined.all
      res_agents = nodes.map{|r| r.to_hash_agent}

      res.set_data({agents: res_agents})
    end

  end
end

