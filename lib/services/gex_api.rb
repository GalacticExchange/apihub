module Services
  class GexApi

    def self.do_admin_request(method, u, data, headers={})
      # TODO: implement

      # auth as admin


      #
      headers['token'] = token
      return do_request(method, u, data, headers)
    end

    def self.do_request(method, u, data, headers={})
      #raise 'do not use API'

      url = Rails.configuration.gex_config[:api_url] + u

      #response = HTTParty.get('http://api.stackexchange.com/2.2/questions?blocks=stackoverflow')
      #puts response.body, response.code, response.message, response.headers.inspect

      headers['Content-Type'] = "application/json"
      headers['Accept'] = "application/json"

      # do http request
      begin
        request_params = {:query=>data, :headers => headers}

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
        return Gexcore::Response.res_error_exception('Unexpected error occurred. Server unavailable', e)
      end

      #
      resp_data = JSON.parse(response.body)

      #
      unless [200,201].include? response.code
        return res_error_from_json_data(resp_data)
      end


      # OK. parse result
      return Gexcore::Response.res_data(resp_data)

    rescue => error
      Gexcore::Response.res_error_exception('Unexpected error occurred. Server unavailable', error)
    end



    def self.res_error_from_json_data(resp_data)
      res = Gexcore::Response.res_error('', '')
      res.error_code = resp_data['code']
      res.error_name = resp_data['errorname']
      res.error_msg = resp_data['message']
      res.error_desc = resp_data['description']

      res.errors = []
      resp_data['errors'].each do |err|
        res.errors << err
      end

      res
    end

  end

end
