module Gexcore::Monitoring

  class SystemMonitoringService < ::Gexcore::BaseService
    COUNTERS = {
        :cpu=>{name: 'CPU'},
        :memory=>{name: 'Memory free'}
    }


    def self.get_server_state_keepalive(server)
      # get counter data
      data = Gexcore::Monitoring::Sensu::ApiService.get_result_value(server[:id], 'keepalive', 600)

      # analyze
      v = Gexcore::Monitoring::Checks::Keepalive.get_value_keepalive(data)
      d = Gexcore::Monitoring::Service.get_date_from_counter_data(data)

      return {
          #value: v,
          value: Gexcore::Monitoring::Service.get_state_name(v),
          date: d
      }
    end



    def self.get_server_state_performance(server, counters=nil)
      counters ||= COUNTERS.keys
      data = {}
      counters.each do |c|
        data[c] = get_server_state_performance_counter server, c
      end

      data
    end

    def self.get_server_state_performance_counter(server, counter_name)
      #
      data = Gexcore::Monitoring::Sensu::ApiService.get_result_value(server[:id], counter_name, 600)
      return nil if data.nil? || data['check'].nil? || data['check']['output'].nil?

      # parse output
      begin
        output = JSON.parse(data['check']['output'])
      rescue => e
        gex_logger.exception('cannot parse counter data', e, {output: data['check']['output']})
        return nil
      end

      # parse value
      v = nil
      mtd = :"get_counter_value_#{counter_name}"
      clsCheck = Gexcore::MonitoringChecks
      if clsCheck.respond_to? mtd
        v = clsCheck.send(mtd, output)
      end

      return nil if v.nil?

      # date
      d = Gexcore::Monitoring::Service.get_date_from_counter_data(data)

      return {
          value: v,
          date: d
      }
    end

  end
end
