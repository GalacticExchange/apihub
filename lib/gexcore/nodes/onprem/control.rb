module Gexcore::Nodes::Onprem
  class Control < Gexcore::BaseService

    def self.start_node(node)
      # starting
      res_event_start = node.begin_start!
      return Response.res_error("node_start_error", 'Wrong node status. Cannot start') if !res_event_start


      #
      action = 'start'
      res_command = Gexcore::Nodes::Control.send_command_to_node(node, action)

      if res_command.error?
        node.set_start_error!

        return Response.res_error("", 'Cannot start node')
      end

      return Response.res_data
    end



    def self.stop_node(node)
      # stopping
      res_event = node.begin_stop!
      return Response.res_error("node_stop_error", 'Wrong node status. Cannot stop') if !res_event


      # send command to node
      action = 'stop'
      #res_command = Gexcore::NodesControlService.send_command(node, 'stop')
      res_command = rabbitmq_add_command_to_queue(node, action)

      if res_command.error?
        node.set_stop_error!

        return Response.res_error("", 'Cannot stop node')
      end

      #
      return Response.res_data
    end

    def self.restart_node(node)
      # restarting
      res_event_restart = node.begin_restart!
      return Response.res_error("node_restart_error", 'Wrong node status. Cannot restart') if !res_event_restart


      ## set containers status
      node.containers.each do |container|
        container.begin_restart!
      end

      # send start command to node
      action = 'restart'
      #res_command = Gexcore::NodesControlService.send_command(node, 'start')
      res_command = rabbitmq_add_command_to_queue(node, action)

      if res_command.error?
        node.set_restart_error!

        return Response.res_error("", 'Cannot restart node')
      end

      #
      return Response.res_data
    end


    ### helpers

    def self.rabbitmq_add_command_to_queue(node, action)
      Gexcore::Nodes::Control.rabbitmq_add_command_to_queue(node, action)
    end

  end

end
