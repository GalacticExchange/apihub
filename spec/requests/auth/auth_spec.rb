RSpec.describe "Auth", :type => :request do
  def post_params(username, pwd)
    auth_info = JSON.parse(File.read('spec/data/auth_body.txt'))

    res = {"username" => username, "password" => pwd}
    res['systemInfo'] = auth_info
    res
  end

  before :each do
    @lib = Gexcore::UsersCreationService

    #
    @sysinfo = build_sysinfo

    # stub
    stub_create_cluster_all

  end


  describe "auth verified" do

    before :each do
      # create user & verify
      @user_hash = build_user_hash

      @username = @user_hash[:username]
      @pwd = @user_hash[:password]

      @user = create_user_active @user_hash

    end


    after :each do

    end

    describe 'success' do

      it "ok - response" do
        # work
        post_auth @username, @pwd

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        # expectation
        expect(resp_data["teamID"]).not_to be_empty
        expect(resp_data["token"]).not_to be_empty
        #expect(resp_data["gatewayIP"]).not_to be_empty

        # teamID correct
        team = Team.get_by_uid resp_data["teamID"]
        expect(team).not_to be_nil

      end

      it 'token' do
        # work
        post_auth @username, @pwd

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        # expect
        token = resp_data["token"]

        # check token
        data = Gexcore::AuthService.jwt_decode(token)

        expect(data['username']).to eq @username


      end

      it 'auth by email' do
        # work
        post_auth @user_hash[:email], @pwd

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        # expectation
        expect(resp_data["token"]).not_to be_empty
        #expect(resp_data["gatewayIP"]).not_to be_empty
      end


      it 'set data in redis' do
        # work
        post_auth @username, @pwd

        #
        user = User.get_by_username @username

        redis_data = Gexcore::ClustersAccessService.redis_get_clusters_access(user)

        expect(redis_data.keys.count).to be >0
        expect(redis_data[user.main_cluster_id.to_s]).to eq "1"
      end
    end


    describe 'errors - bad input' do
      it 'bad name' do
        # prepare
        badname =  generate_email

        # work
        post_auth badname, @pwd

        #
        resp = last_response

        # expectation
        expect(resp.status).to eq(400)
      end

      it 'blank username' do
        # prepare
        blankname =  ""

        # work
        post_auth blankname, @pwd

        #
        resp = last_response

        # expectation
        expect(resp.status).to eq(400)
      end

      it 'blank password' do
        # prepare
        blankpwd = ""

        # work
        post_auth @username, blankpwd

        #
        resp = last_response

        # expectation
        resp.should_not be_ok
        expect(resp.status).to eq(400)
      end

      it 'bad password' do
        # prepare
        badpwd = 'badpass'+Gexcore::Common.random_string(8)

        # work
        post_auth @username, badpwd

        #
        resp = last_response

        # expectation
        expect(resp.status).to eq(401)
      end
    end


    describe 'errors - not verified' do
      before :each do
        # create user & verify
        @user_hash = build_user_hash
        @u = @lib.build_user_from_params(@user_hash)
        res = @lib.create_user_not_verified(@u, @sysinfo)

        #
        @username = @user_hash[:username]
        @pwd = @user_hash[:password]

        @user = User.get_by_username @username

      end


      it 'not verified' do
        # prepare

        # work
        post_auth @username, @pwd

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        # expectation
        expect(resp.status).to eq(401)
        expect(resp_errorname(resp_data)).to eq 'auth_not_verified'
      end
    end


  end


  describe 'logout' do
    before :each do
      @user_hash = build_user_hash
      @user = create_user_active(@user_hash)
    end


    after :each do

    end

    it 'logout' do
      #
      post_auth @user_hash[:username], @user_hash[:password]

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      delete_json '/logout', {}, {'token' => resp_data['token']}
      #post_json '/logout', {}, {'token' => resp_data['token']}

      #
      resp = last_response
      expect(resp.status).to eq 200


    end

    it 'auth invalid' do
      #
      post_auth @user_hash[:username], @user_hash[:password]

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      token = resp_data['token']

      # try command
      get_json '/userInfo', {}, {'token' => token}

      resp = last_response
      expect(resp.status).to eq 200

      # logout
      delete_json '/logout', {}, {'token' => token}

      # work - try login again
      get_json '/userInfo', {}, {'token' => token}

      #
      resp = last_response
      expect(resp.status).to eq 403

    end

  end


  describe 'login for invited user' do
    before :each do
      @user_hash = build_user_hash
      @user, @cluster = create_user_and_cluster_onprem({}, @user_hash)

      # user2
      @user2_hash = build_user_hash
      @user2 = create_user_active_in_team(@user.team_id, @user2_hash)

    end


    after :each do

    end

    it 'invited user can login' do
      # login - ok
      post_auth @user2_hash[:username], @user2_hash[:password]

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      token = resp_data['token']

      expect(token).to be_truthy
    end

  end

  describe 'deleted user' do
    before :each do
      @user_hash = build_user_hash
      @user, @cluster = create_user_and_cluster_onprem({}, @user_hash)

      # user2
      @user2_hash = build_user_hash
      @user2 = create_user_active_in_team(@user.team_id, @user2_hash)

    end


    after :each do

    end

    it 'for deleted user' do
      # login - ok
      post_auth @user2_hash[:username], @user2_hash[:password]

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      token = resp_data['token']

      # do smth
      get_json "/clusters/#{@cluster.uid}/info", {}, {token: token}

      resp = last_response
      expect(resp.status).to eq 200

      # delete user
      Gexcore::UsersService.delete_user_in_team(@user2)

      # try do smth with old token
      get_json '/clusterInfo', {}, {token: token}

      #
      resp = last_response
      expect(resp.status).to eq 403

    end
  end
end
