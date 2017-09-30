module RequestHelpers

  def last_response
    response
  end

  def response_json
    JSON.parse(response.body)
  end

  def last_response_json
    JSON.parse(last_response.body)  rescue nil
  end

  def post_json(url, data, headers={})
    headers['HTTP_ACCEPT'] =  "application/json"
    #post url, data, headers
    post url, params: data, headers: headers


    # 'HTTP_ACCEPT' => "application/json" -- OK
    #  'Accept' => "application/json", 'accept' => "application/json",        'format'=> 'application/json'

    #'CONTENT_TYPE' => 'application/json', "Content-Type" => "application/json",
    #'HTTP_ACCEPT' => "application/json", 'Accept' => "application/json", 'accept' => "application/json",
    #'format'=> 'application/json'

    last_response_json
  end

  def put_json(url, data, headers={})
    headers['HTTP_ACCEPT'] =  "application/json"
    put url, params: data, headers: headers


    last_response_json
  end



  def get_json(url, data, headers={})
    headers['HTTP_ACCEPT'] =  "application/json"
    get url, data, headers


    last_response_json
  end

  def delete_json(url, data, headers={})
    headers['HTTP_ACCEPT'] =  "application/json"
    delete url, data, headers

    last_response_json
  end

  def resp_errorname(resp_data)
    resp_data['errorname'].downcase
  end

end
