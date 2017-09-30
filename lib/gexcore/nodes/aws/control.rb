module Gexcore::Nodes::Aws
  class Control < Gexcore::BaseService


    ### operations with node

    def self.start_node(node)
      res = response_init

      # starting
      res_event_start = node.begin_start!
      return Response.res_error("node_start_error", 'Wrong node status. Cannot start') if !res_event_start


      ## provision - starts AWS instance
      res_aws = Gexcore::Nodes::Aws::Provision.start_node(node)

      # error
      if res_aws.error?
        node.set_start_error!
        return res.set_error("node_start_error", 'Cannot start node')
      end


      ## send command to gexd
      res_command = Gexcore::Nodes::Control.send_command_to_node(node, 'start')
      if res_command.error?
        node.set_start_error!
        return res.set_error("node_start_error", 'Cannot start node')
      end

      # OK
      return res.set_data
    end


    def self.stop_node(node)
      res = response_init

      # stopping
      res_event = node.begin_stop!
      return Response.res_error("node_stop_error", 'Wrong node status. Cannot stop') if !res_event


      ### stop AWS instance
      res_provision = Gexcore::Nodes::Aws::Provision.stop_node(node)

      # error
      if res_provision.error?
        node.set_stop_error!

        return res.set_error("", 'Cannot stop node')
      end

      # OK
      node.finish_stop!


      return res.set_data
    end

    def self.restart_node(node)
      res = response_init

      ### restarting
      res_event_restart = node.begin_restart!
      return Response.res_error("node_restart_error", 'Wrong node status. Cannot restart') if !res_event_restart


      ### restart AWS instance
      res_provision = Gexcore::Nodes::Aws::Provision.restart_node(node)

      # error
      if res_provision.error?
        node.set_restart_error!
        return res.set_error("", 'Cannot restart node')
      end

      ### send command to node
      res_command = Gexcore::Nodes::Control.send_command_to_node(node, 'restart')
      if res_command.error?
        node.set_restart_error!
        return res.set_error("", 'Cannot restart node')
      end

      #
      return res.set_data
    end


  end
end


