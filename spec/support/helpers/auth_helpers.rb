module AuthHelpers

  def auth_user_hash(user_hash)
    pwd = user_hash[:pwd] || user_hash[:password]
    auth_user user_hash[:username], pwd
  end


  def auth_user(username, pwd)
    post_auth username, pwd

    resp_data = response_json
    resp_data["token"]
  end

  def post_auth(username, pwd)
    auth_info = JSON.parse(File.read('spec/data/auth_body.txt'))

    auth_body_hash = {"username" => username, "password" => pwd}
    auth_body_hash['systemInfo'] = auth_info

    post_json '/login', auth_body_hash, {}

  end


  def auth_token(user)
    token = Gexcore::AuthService.jwt_generate user

    token
  end


end
