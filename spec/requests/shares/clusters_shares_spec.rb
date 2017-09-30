RSpec.describe "cluster shares list for user", :type => :request do

  describe 'get shared clusters list info' do

    before :each do
      @lib = Gexcore::Shares::Service

      # stub
      stub_create_cluster_all

      #
      @admin_hash = build_user_hash
      @admin = create_user_active_and_create_cluster @admin_hash
      @cluster = @admin.home_cluster
      @team = Team.find(@cluster.team_id)
    end

    after :each do

    end

    it "ok" do
      # prepare
      user_hash = build_user_hash
      user = create_user_active_and_create_cluster user_hash

      # share create to user
      @lib.create_share_by_admin(@admin, @cluster, user.username)

      # auth user
      token = auth_user_hash(user_hash)

      # work get clusters for user
      get_json '/clusterShares', {}, {"token" => token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)
      #
      expect(resp_data["data"]["clusters"][0]["name"]).to eq @cluster.name
      expect(resp_data["data"]["clusters"][0]["id"]).to eq @cluster.uid


    end

  end
end
