module Gexcore::Monitoring

  class ServicesMonitoring < Gexcore::BaseService

    CHECKS = {

        'hue' =>{
            'port' => {
                'name' => 'port',
                'title' => 'Port opened'
            },
        },

        'elasticsearch' =>{
            'port' => {
                'name' => 'port',
                'title' => 'Port opened'
            },
            'response' => {
                'name' => 'response',
                'title' => 'Response from service'
            }
        },
        'kibana' =>{
            'port' => {
                'name' => 'port',
                'title' => 'Port opened'
            },
        },
    }

    CHECK_SERVICE_SENSU_COUNTER_NAME = 'docker_services_status'


    ###
    def self.get_for_services_by_user(user, ids)
      team_id = user.team_id

      # filter for this user
      clusters_ids = user.team.clusters.w_not_deleted.pluck(:id)
      services = ClusterService.where(cluster_id: clusters_ids, id: ids).all

      res = {}
      services.each do |service|
        res[service.id] = get_for_service(service)
      end

      res
    end


    def self.get_for_service(service)
      data = {}

      # check - container running
      #data['docker_container_running'] = Gexcore::ContainersMonitoring.get_check_data(service.container, 'docker_container_running')


      #
      service_name = service_name_for_service(service)
      container_name = container_name_for_service(service)


      # data from docker_services_status
      check_sensu_data = get_check_data_all(service)

      # TODO: cache
      check_data_service = nil
      begin
        if check_sensu_data
          check_data_service = check_sensu_data[container_name]['services'][service_name]
        end
      rescue => e

      end

      return data unless check_data_service

      # parse result from sensu
      if CHECKS[service_name]
        a_checks = CHECKS[service_name].keys
      else
        a_checks = check_data_service.keys
      end


      a_checks.each do |check_name|
        #
        res_check = Gexcore::Monitoring::Checks::Result.new(check_name)
        res_check.set_failed

        #
        check_info = (CHECKS[service_name][check_name]  rescue nil)


        check_data = check_data_service[check_name]

        #
        if check_data
          res_check.description = check_data['title']

          if check_data['res']
            res_check.set_passed
          end

          #res_check.output = check_data['output']
        end

        res_check.description ||= check_info['title'] rescue nil

        #
        data[check_name] = res_check
      end



      data
    end


    def self.service_name_for_service(service)
      s = service.name
      s = 'elasticsearch' if s =='elastic'
      s
    end

    def self.container_name_for_service(service)
      #Gexcore::AppHadoop::App::CONTAINERS_BY_SERVICE_SLAVE[service.name]
      service.container.basename

    end


    ###

    def self.get_check_data_all(service)
      #
      node = service.node
      return nil if node.nil?

      # get data from sensu
      sensu_node_uid = 'node_' + node.uid
      data = Gexcore::Monitoring::Sensu::ApiService.get_result_value(
          sensu_node_uid, CHECK_SERVICE_SENSU_COUNTER_NAME, 600)

      return nil if data.nil? || data['check'].nil? || data['check']['output'].nil?


      # parse json
      data_hash =nil
      begin
        data_hash = JSON.parse(data['check']['output'])
      rescue => e
        data_hash = nil
      end

      data_hash
    end

=begin
    def self.get_check_data(service, check_name)
      node = service.node
      return nil if node.nil?

      check_info = CHECKS[check_name]

      # get data from sensu
      sensu_node_uid = 'node_' + node.uid
      data = Gexcore::Monitoring::Sensu::ApiService.get_result_value(
          sensu_node_uid, check_info[:sensu_counter_name], 600)

      return nil if data.nil? || data['check'].nil? || data['check']['output'].nil?


      # get value from counter data
      mtd = check_info[:method_check_value]

      if respond_to?(mtd)
        v = send(mtd, service, check_info, data['check']['output'])
        return v
      end

      # return raw data
      data['check']['output']
    end
=end



  end
end

