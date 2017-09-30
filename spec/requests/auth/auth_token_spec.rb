RSpec.describe "Auth", :type => :request do
  def post_params(username, pwd)
    res = {"username" => username, "password" => pwd}
    res['systemInfo'] = @auth_info
    res
  end




  describe 'valid token' do

    before :each do
      @lib = Gexcore::UsersCreationService

      #
      stub_create_user_all

      #
      @user_hash = build_user_hash
      @user = create_user_active(@user_hash)
      @username = @user_hash[:username]
      @pwd = @user_hash[:password]
    end


    it 'valid token' do
      #
      post_json '/login', post_params(@username, @pwd), {}


      #
      resp = last_response
      resp_data = JSON.parse(resp.body)


      # expectation
      token = resp_data["token"]

      # try any command
      get_json '/userInfo', {}, {"token" => token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      expect(resp.status).to eq 200

    end


  end

  describe 'invalid token' do

    before :each do
      @lib = Gexcore::UsersCreationService

      #
      stub_create_user_all

      #
      @user_hash = build_user_hash
      @user = create_user_active(@user_hash)
      @username = @user_hash[:username]
      @pwd = @user_hash[:password]
    end


    it 'invalid token' do
      #
      post_json '/login', post_params(@username, @pwd), {}


      #
      resp = last_response
      resp_data = JSON.parse(resp.body)


      # expectation
      token = resp_data["token"]

      # bad token
      token = '1'+token

      # try any command
      get_json '/userInfo', {}, {token: token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      expect(resp.status).to eq 403
      expect(resp_data['errorname']).to eq 'TOKEN_INVALID'


    end

    it 'expired token' do
      #
      post_json '/login', post_params(@username, @pwd), {}


      #
      resp = last_response
      resp_data = JSON.parse(resp.body)


      # expectation
      token = resp_data["token"]

      # time pass
      Timecop.travel(Time.now.months_since(2)) do
        # try any command
        get_json '/userInfo', {}, {token: token}

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        expect(resp.status).to eq 403
        expect(resp_data['errorname']).to eq 'TOKEN_EXPIRED'
      end

    end

  end



  describe 'refresh token by node' do
    before :each do
      @lib = Gexcore::UsersCreationService

      #
      stub_create_user_all

      #
      @user_hash = build_user_hash
      @user, @cluster = create_user_and_cluster_onprem({}, @user_hash)
      @username = @user_hash[:username]
      @pwd = @user_hash[:password]
    end

    before :each do
      #
      post_json '/login', post_params(@username, @pwd), {}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      # get token
      @token = resp_data["token"]

      # install node
      stub_create_node_all
      @node = create_node_active(@cluster)

      # agent token
      @node_agent_token = @node.agent_token

    end


    it 'refresh expired token' do

      # time pass
      Timecop.travel(Time.now + (Gexcore::AuthService::TOKEN_TTL_HOURS+2).hours) do
        # refresh token
        post_json '/tokens/refresh', {token: @token, nodeAgentToken: @node_agent_token}, {}

        #
        resp_new = last_response
        resp_data_new = JSON.parse(resp_new.body)

        # get token
        token_new = resp_data_new["token"]


        # try any command
        get_json '/userInfo', {}, {"token" => token_new}

        #
        resp3 = last_response

        expect(resp3.status).to eq 200

      end

    end

    it 'bad token' do
      # refresh token
      post_json '/tokens/refresh', {token: @token+'00', nodeAgentToken: @node_agent_token+'00'}, {}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 400
      expect(resp_data['token']).to be_nil

    end

    it 'bad agent token' do
      # refresh token
      post_json '/tokens/refresh', {token: @token, nodeAgentToken: @node_agent_token+'00'}, {}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 400
      expect(resp_data['token']).to be_nil

    end

    it 'node not belong to user' do
      # user2
      @user2_hash = build_user_hash
      @user2 = create_user_and_cluster_onprem(@user2_hash, @user2_hash)

      @user2_token = auth_user_hash(@user2_hash)



      # refresh token
      post_json '/tokens/refresh', {token: @user2_token, nodeAgentToken: @node_agent_token}, {}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 403
      expect(resp_data['token']).to be_nil

    end

  end
end

=begin

    TOKEN_TTL_HOURS_PLUS = 24*31

    def self.jump_in_time_for_a_month_and_a_day(token)
      data = jwt_decode(token)
      data['exp'] = Time.now.months_ago(2).to_i

      res = Response.new
      res.sysdata[:data] = data

      return res.set_error('token_invalid', 'Token invalid', 'cannot parse token') if data.nil?

      res

    end


    def self.exp_from_now_plus_day(ttl_hours = TOKEN_TTL_HOURS_PLUS)
      ttl_hours.hours.from_now.to_i
    end

=end
