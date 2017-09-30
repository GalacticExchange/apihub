module Gexcore::Monitoring::Sensu

  class ApiRequest < ::Gexcore::BaseService

    def self.do_request(method, url, p={}, headers={})
      #require 'httparty'


      #
      headers['Content-Type'] = "application/json"
      headers['Accept'] = "application/json"

      begin
        request_params = {query: p, headers: headers, timeout: 2}
        #request_params = {query: p, headers: headers}

        if method==:post
          response = HTTParty.post(url, request_params)
        elsif method==:get
          response = HTTParty.get(url, request_params)
        elsif method==:put
          response = HTTParty.put(url, request_params)
        elsif method==:delete
          response = HTTParty.delete(url, request_params)
        end

      rescue HTTParty::Error => e
        return Response.res_error_exception('Unexpected error occurred. Server unavailable', e)
      rescue => e
        return Response.res_error_exception('Unexpected error occurred. Server unavailable', e)
      end

      #
      raise "Bad data" unless [200,201].include?(response.code)

      #
      resp_data = JSON.parse(response.body)

      # OK. parse result
      return Response.res_data(resp_data)

    rescue => error
      Response.res_error_exception('Unexpected error occurred. Server unavailable', error)
    end

    def self.do_auth_request(method, path, p={}, headers={})
      url = make_auth_url(path)
      #gex_logger.debug('debug_sensu_redis', "path: #{path}", {path: path, url: url})
      return do_request(method, url, p, headers)
    end


    def self.make_auth_url(path)
      url_base = "http://#{config.sensu_api_user}:#{config.sensu_api_password}@#{config.sensu_api_host_private}:#{config.sensu_api_port}/"

      "#{url_base}#{path}"
    end

  end
end

