module Gexcore::Monitoring::Sensu

  class ApiService < ::Gexcore::BaseService
    #
    def self.get_result_value(node_uid, check_name, ttl=600)
      # request sensu-api
      path = make_path_result(node_uid, check_name)
      res = Gexcore::Monitoring::Sensu::ApiRequest.do_auth_request(:get, path)

      return nil if res.error?

      # parse result from sensu api
      data = res.data
      return nil if data.nil? || data.keys.empty?

      #begin
        # date
        sd = data['check']['executed']
        d = Time.at(sd.to_i).utc.to_datetime
        raise 'Cannot parse counter data - bad date' if d.nil?

        now = Time.now.utc
        raise 'Counter data is too old' if now.to_f-d.to_f > ttl

        # status
        #status = data['check']['status'].to_i

      #rescue => e_parse
        #gex_logger.debug_exception('counter', "cannot parse counter data", e_parse, data)
      #end

      return data
    rescue => e
      #gex_logger.debug_exception('counter', 'Cannot process request', e, {})
      return nil
    end

    def self.make_path_result(node_uid, check_name)
      "results/#{node_uid}/#{check_name}"
    end

  end
end

