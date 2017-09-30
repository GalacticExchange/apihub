module Gexcore
  module Containers
    class Control < Gexcore::BaseService
      # actions
      ACTIONS = ['restart', 'stop', 'start', 'set_start_error', 'set_stop_error', 'set_restart_error']


      ###
      def self.do_action_by_user(user, container_or_id, cmd)
        # user not exists
        return Response.res_error_badinput("", 'user not found', 'user not found') if user.nil?

        # container
        if container_or_id.is_a? Integer
          container = ClusterContainer.find container_or_id
        else
          container = container_or_id
        end

        return Response.res_error('', 'Container not set') if container.nil?

        # check permissions
        if !(user.can? :manage, container.cluster)
          return Response.res_error_forbidden("container_control_error", 'No permissions to manage container')
        end

        return Gexcore::Containers::Control.do_action(container, cmd)
      end



      ###
      def self.do_action(container_or_id, cmd)
        res = Response.new

        # container
        if container_or_id.is_a? Integer
          container = ClusterContainer.find container_or_id
        else
          container = container_or_id
        end

        return res.res_error('', 'Container not set') if container.nil?


        #
        res.sysdata[:container_id] = container.id

        # validate
        res_validate = validate_action(cmd)
        return res_validate if res_validate.error?


        # mtd
        mtd = :"#{cmd}_container"
        if respond_to?(mtd)
          return send(mtd, container)
        end


        res.set_error('container_control_error', 'Bad command')
        res
      end


      ###

      def self.validate_action(cmd)
        cmd = cmd.to_s.downcase
        if !ACTIONS.include? cmd
          return Response.res_error('', 'unknown action', "unknown action #{cmd}")
        end

        return Response.res_data
      end



      ### start

      def self.start_container(container)
        # starting
        res_event_start = container.begin_start!
        return Response.res_error("container_start_error", 'Wrong container status. Cannot start') if !res_event_start

        # work
        if container.node_id
          send_container_command_to_node(container, 'startContainer')
        else
          ContainerControlWorker.perform_async(container.id, 'start', get_env)
        end




        #
        return Response.res_data
      end


      def self.set_start_error(container)
        res_event = container.set_start_error!

        #log_error(container, "container_status_change_error", 'Wrong container status. Cannot start')
        return Response.res_error("container_change_status_error", 'Wrong container status. Cannot start') if !res_event


        #
        return Response.res_data
      end



      ### restart

      def self.restart_container(container)
        # restarting
        res_event_restart = container.begin_restart!
        return Response.res_error("container_restart_error", 'Wrong container status. Cannot restart') if !res_event_restart

        # work
        if container.node_id
          send_container_command_to_node(container, 'restartContainer')
        else
          ContainerControlWorker.perform_async(container.id, 'restart', get_env)
        end

        #
        return Response.res_data
      end


      def self.set_restart_error(container)
        res_event = container.set_restart_error!
        return Response.res_error("container_change_status_error", 'Wrong container status. Cannot start') if !res_event

        #
        return Response.res_data
      end



      ### stop

      def self.stop_container(container)
        # stopping
        res_event = container.begin_stop!
        return Response.res_error("container_stop_error", 'Wrong container status. Cannot stop') if !res_event

        # work
        if container.node_id
          send_container_command_to_node(container, 'stopContainer')
        else
          ContainerControlWorker.perform_async(container.id, 'stop', get_env)
        end

        #
        return Response.res_data
      end


      def self.set_stop_error(container)
        res_event = container.set_stop_error!
        return Response.res_error("container_change_status_error", 'Wrong container status') if !res_event

        #
        return Response.res_data
      end



      ### helpers

      def self.send_container_command_to_node(container, action)
        node = container.node
        gex_logger.debug("debug_rabbit", "start send_command_to_node", {container_id: container.id, node_id: node.id})

        p = {
            containerID: container.uid,
            containerName: container.name,
            containerBasename: container.basename,
            applicationID: container.application.uid

        }

        return Gexcore::Nodes::Control.rabbitmq_add_command_to_queue(node, action, p)
      end



      ### common
      def self.log_error(container, type_name, msg, msg_sys="")
        gex_logger.error(
            type_name,
            msg,
            {
                container_id: container.id,
            }
        )
      end


    end
  end
end
