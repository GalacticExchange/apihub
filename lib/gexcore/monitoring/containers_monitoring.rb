module Gexcore::Monitoring

  class ContainersMonitoring < Gexcore::BaseService
    CHECKS = {
        'docker_container_running' => {
            name: 'docker_container_running',
            title: 'Docker container is running',
            sensu_counter_name: 'metrics_docker_stats',
            #method_check_value: "get_check_value_container_running"
            class_name: 'DockerContainerRunning'


        }

    }



    ###
    def self.get_for_containers_by_user(user, uids)
      team_id = user.team_id

      # filter for this user
      clusters_ids = user.team.clusters.w_not_deleted.pluck(:id)

      containers = ClusterContainer.where(cluster_id: clusters_ids, uid: uids).all

      res = {}
      containers.each do |container|
        res[container.uid] = get_for_container(container)
      end

      res
    end

    ###
    def self.get_for_container_by_user(user, uid)
      team_id = user.team_id

      container = ClusterContainer.get_by_uid(uid)
      res = {}

      return res unless container
      res = get_for_container(container)

      res
    end



    def self.get_for_container(container)
      data = {}

      return nil if container.node_id.nil?

      CHECKS.each do |check_name, check_info|
        result = get_check_data(container, check_name)
        data[check_name] = result if result
      end

      data
    end


    ###

    def self.get_check_data(container, check_name)
      # get data from sensu
      check_data = get_sensu_counter_data(container, check_name)

      # build check result
      return Gexcore::Monitoring::Checks::Result.build_from_sensu_check_data(
          check_data,
          check_name, CHECKS[check_name],
          {container: container}
      )
    end


    ### sensu helpers

    def self.get_sensu_counter_data(container, check_name)
      return nil if container.node.nil?

      check_info = CHECKS[check_name]
      sensu_node_uid = 'node_' + container.node.uid

      #
      data = Gexcore::Monitoring::Sensu::ApiService.get_result_value(sensu_node_uid, check_info[:sensu_counter_name], 600)

      if data.nil? || data['check'].nil? || data['check']['output'].nil?
        return nil
      end

      data
    end




  end
end

