RSpec.describe "share cluster", :type => :request do
  before :each do
    #
    stub_create_cluster_all

    #
    @lib = Gexcore::UsersCreationService
    @clsResp = Gexcore::Response
  end


  describe 'create share' do

    before :each do
      @admin_hash = build_user_hash
      @admin = create_user_active_and_create_cluster @admin_hash

      #

      # create another user
      @user_hash = build_user_hash
      @user = create_user_active_and_create_cluster @user_hash
      #@share_username =  generate_username
      @share_username = @user.username

      #
      @cluster = Cluster.find(@admin.main_cluster_id)


      # auth main user
      @token = auth_user_hash(@admin_hash)

    end

    after :each do

    end


    describe 'success path' do

      it "ok - response" do
        # prepare

        # work
        post_json '/shares', {"username" => @share_username}, {"token" => @token}

        resp = last_response
        resp_data = JSON.parse(resp.body)

        # expectation
        expect(resp.status).to eq(200)
        #expect(@resp_data).to be_empty

      end

      it 'data in DB' do
        # work
        post_json '/shares', {"username" => @share_username}, {"token" => @token}


        #
        user = User.get_by_username @share_username

        # access cluster
        expect(ClusterAccess.has_access?(@cluster.id, user.id)).to eq true
      end

      it 'update data in Redis' do
        # work
        post_json '/shares', {"username" => @share_username}, {"token" => @token}


        #
        user = User.get_by_username @share_username

        # access cluster
        redis_data = Gexcore::ClustersAccessService.redis_get_clusters_access(user)

        expect(redis_data.keys.count).to be >0
        expect(redis_data[@cluster.id.to_s]).to eq "1"
      end

    end

    describe 'errors' do
      it "invited user exists in our team => 400" do
        # prepare
        user_hash = build_user_hash
        user = create_user_active_in_team(@admin.team_id, user_hash)

        # work
        post_json '/shares', {"username" => user.username}, {"token" => @token}

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        # expectation
        expect(resp.status).to eq(400)

      end


      it 'share exists' do
        # prepare
        post_json '/shares', {"username" => @share_username}, {"tokenId" => @token}

        # share again
        post_json '/shares', {"username" => @share_username}, {"tokenId" => @token}

        # check
        resp = last_response
        resp_data = JSON.parse(resp.body)

        #
        expect(resp.status).to eq(400)

        #
        user = User.get_by_username @share_username

        # access cluster
        expect(ClusterAccess.has_access?(@cluster.id, user.id)).to eq true
      end


    end

  end


end
