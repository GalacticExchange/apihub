module Gexcore::Nodes

  class Control < Gexcore::BaseService
    # actions
    ACTIONS = ['restart', 'stop', 'start', 'reconnect', 'set_start_error', 'set_stop_error', 'set_restart_error']



    ### log
    def self.log_status_change(node)
      gex_logger.info(
          "node_status_changed",
          "Node #{node.name}. Status changed from #{node.status_name(node.aasm.current_state)} to #{node.status_name(node.aasm.to_state)}",
          {
              node_id: node.id,
              node_uid: node.uid,
              from: node.aasm.current_state,
              to: node.aasm.to_state,
              event: node.aasm.current_event}
      )
    end

    ###
    def self.do_action_with_node_by_user(user, node, cmd)
      # user not exists
      return Response.res_error_badinput("", 'user not found', 'user not found') if user.nil?

      # node empty
      return Response.res_error_badinput("", 'Node not found', 'Node not found') if node.nil?


      # check permissions
      if !(user.can? :manage, node.cluster)
        return Response.res_error_forbidden("view_service_error", 'No permissions to view service')
      end

      return Gexcore::Nodes::Control.do_action_with_node(node, cmd)
    end


      ###
      def self.do_action_with_node(node_or_id, cmd)
        res = Response.new

        # node
        if node_or_id.is_a? Integer
          node = Node.find node_or_id
        else
          node = node_or_id
        end

        return res.set_error('', 'node not set') if node.nil?

        #
        res.sysdata[:node_id] = node.id

        #
        cmd = cmd.to_s.downcase
        if !Gexcore::Nodes::Control::ACTIONS.include? cmd
          return res.set_error('', 'unknown action', "unknown action #{action}")
        end


        #
        mtd = :"#{cmd}_node"
        if Gexcore::Nodes::Control.respond_to?(mtd)
          return Gexcore::Nodes::Control.send(mtd, node)
        end



        res.set_error('node_control_error', 'Bad command')
        res
      end

      ### start node

      def self.start_node(node)
        if node.node_type_name==ClusterType::ONPREM
          return Gexcore::Nodes::Onprem::Control.start_node(node)
        elsif node.node_type_name==ClusterType::AWS
          return Gexcore::Nodes::Aws::Control.start_node(node)
        end

        #
        return Response.res_data
      end


      def self.set_start_error_node(node)
        res_event = node.set_start_error!

        log_error(node, "node_status_change_error", 'Wrong node status. Cannot start')
        return Response.res_error("node_change_status_error", 'Wrong node status. Cannot start') if !res_event


        #
        return Response.res_data
      end



      ### restart node

      def self.restart_node(node)
        # work
        if node.node_type_name==ClusterType::ONPREM
          return Gexcore::Nodes::Onprem::Control.restart_node(node)
        elsif node.node_type_name==ClusterType::AWS
          return Gexcore::Nodes::Aws::Control.restart_node(node)
        end

        #
        return Response.res_data
      end


      def self.set_restart_error_node(node)
        res_event = node.set_restart_error!
        return Response.res_error("node_change_status_error", 'Wrong node status. Cannot start') if !res_event

        #
        return Response.res_data
      end


      ### stop node

      def self.stop_node(node)
        # send start command to node
        if node.node_type_name==ClusterType::ONPREM
          return Gexcore::Nodes::Onprem::Control.stop_node(node)
        elsif node.node_type_name==ClusterType::AWS
          return Gexcore::Nodes::Aws::Control.stop_node(node)
        end

        #
        return Response.res_data
      end


      def self.set_stop_error_node(node)
        res_event = node.set_stop_error!
        return Response.res_error("node_change_status_error", 'Wrong node status. Cannot start') if !res_event

        #
        return Response.res_data
      end


      ## cmd -reconnect

      def self.reconnect_node(node)
        action  = 'reconnect'
        res_command = rabbitmq_add_command_to_queue(node, action)

        return res_command
      end




      ### helpers
      def self.send_command_to_node(node, action, action_params={})
        gex_logger.debug("debug_rabbit", "start send_command_to_node")

        return rabbitmq_add_command_to_queue(node, action, action_params)
      end


      ### RabbitMQ operations - send command

      def self.rabbitmq_add_command_to_queue(node, action, action_params={})

        gex_logger.debug("debug_rabbit", "start rabbitmq_add_command_to_queue")

        begin
          #
          conn = Bunny.new(
              :host => config.rabbit_url_private,
              :port=>5672, :vhost=>'/',
              :user => config.rabbit_root_username, :password => config.rabbit_root_password,
              # v1
              #:continuation_timeout => 180000,
              #:heartbeat => 30,
              #:automatically_recover => true,
              #:network_recovery_interval => 3,
              #:recover_from_connection_close => true,
              # v2
              :continuation_timeout => 180000, # ms
              :heartbeat => 5*60, # sec
              :automatically_recover => false,
              :network_recovery_interval => 3,
              :recover_from_connection_close => false,
          )
          conn.start
          ch = conn.create_channel

          # exchange
          exchange = ch.topic(rabbit_exchange_node_commands(node))

          # queue
          key = rabbit_queue_node_commands(node)
          q1 = ch.queue(key, :auto_delete => false, :exclusive => false, :durable=>false).bind(exchange, :routing_key => key)
          # , :auto_delete => true

          # push
          cmd = {command: action}.merge(action_params)
          exchange.publish(cmd.to_json, :routing_key => key)

          gex_logger.debug("debug_rabbit", "Command sent to RabbitMQ", {cmd: cmd, queue: key})

          #
          ch.close
          conn.close

        rescue => e
          gex_logger.error("debug_rabbit", "Error rabbit", {node_id: node.id, e: {msg: e.message}})

          res = Response.res_error_exception('cannot send command to node', e)

          gex_logger.debug_response res, "cannot send command to node", {node_id: node.id}
          return res
        end

        # close connection
        begin
          if ch && ch.open?
            begin
              ch.close
            rescue =>e
              gex_logger.debug "exception", "exception", {e: e.message}
            end

          end

          if conn && conn.open?
            begin
              conn.close
            rescue => e
              gex_logger.debug "exception", "exception", {e: e.message}
            end
          end

        rescue => e
          gex_logger.debug "exception", "rabbit close exception", {node_id: node.id, e: e.inspect}
        end

        #
        gex_logger.debug "debug_node_control", "command sent to node: #{action}", {node_id: node.id, cmd: action}


        Response.res_data
      end

      def self.rabbit_exchange_node_commands(node)
        config.rabbit_prefix+".nodes.#{node.uid}.exchange"
      end

      def self.rabbit_queue_node_commands(node)
        config.rabbit_prefix+".nodes.#{node.uid}.commands"
      end



      ### rabbitmq management
      def self.rabbitmq_create_user_for_node(node)
        gex_logger.debug "debug_rabbit", "rabbitmq_create_user_for_node - start", {node_id: node.id}

        begin
          require "rabbitmq/http/client"

          client = RabbitMQ::HTTP::Client.new(
              config.rabbit_api_endpoint_private,
              :username => config.rabbit_root_username, :password => config.rabbit_root_password)

          username = "node#{node.uid}"
          pwd = node.agent_token

          #
          res = client.update_user(username, :name=>username, :password=>pwd, :tags=>"")
          #gex_logger.debug "debug_rabbit", "rabbitmq_create_user_for_node - res", {node_id: node.id, res: res}

          perms = config.rabbit_prefix+".nodes.#{node.uid}.*"
          ps = client.update_permissions_of("/", username, :write => perms, :read => perms, :configure => perms)

          # log
          gex_logger.debug "debug_rabbit", "rabbitmq_create_user_for_node - FINISH OK", {node_id: node.id, u: username}

        rescue => e
          gex_logger.debug "debug_rabbit", "cannot create RabbitMQ user for node", {node_id: node.id}

          gex_logger.exception "cannot create RabbitMQ user for node", e, {node_id: node.id}

          res = Response.res_error_exception('Error', e)
          return res
        end

        Response.res_data
      end

      def self.rabbitmq_delete_all_for_node(node)
        gex_logger.debug "", "rabbitmq_delete_user_for_node - start", {node_id: node.id}

        begin
          require "rabbitmq/http/client"

          client = RabbitMQ::HTTP::Client.new(
              config.rabbit_api_endpoint_private,
              :username => config.rabbit_root_username,
              :password => config.rabbit_root_password)


          # user
          username = "node#{node.uid}"
          pwd = node.agent_token

          #
          gex_logger.debug "debug_delete_node", "before delete_user", {node_id: node.id}

          begin
            client.delete_user(username)
          rescue Faraday::ResourceNotFound => ex_user_notfound
            #rescue => ex_user_notfound
            gex_logger.debug "debug_delete_node", "user not found in RabbitMQ", {node_id: node.id}
          end

          gex_logger.debug "debug_delete_node", "deleted user", {node_id: node.id}

          # queue, exchange
          begin
            client.delete_queue("/", rabbit_queue_node_commands(node))
          rescue Faraday::ResourceNotFound => ex_q_notfound
            gex_logger.debug "debug_delete_node", "queue not found in RabbitMQ", {node_id: node.id}
          end

          gex_logger.debug "debug_delete_node", "deleted queue", {node_id: node.id}
          begin
            client.delete_exchange("/", rabbit_exchange_node_commands(node))
          rescue Faraday::ResourceNotFound => ex_ch_notfound
            gex_logger.debug "debug_delete_node", "exchange not found in RabbitMQ", {node_id: node.id}
          end

          gex_logger.debug "debug_delete_node", "deleted exchange", {node_id: node.id}

        rescue => e
          gex_logger.exception "cannot delete RabbitMQ data for node", e, {node_id: node.id}

          res = Response.res_error_exception('Error', e)
          return res
        end

        Response.res_data
      end



      ### common
      def self.log_error(node, type_name, msg, msg_sys="")
        gex_logger.error(
            type_name,
            msg,
            {
                node_id: node.id,
                node_uid: node.uid
            }
        )
      end


    end
end
