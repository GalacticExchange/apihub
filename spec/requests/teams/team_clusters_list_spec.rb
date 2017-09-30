RSpec.describe "clusters list in team", :type => :request do

  before :each do
    #
    stub_create_cluster_all
  end

  describe 'get clusters list in team' do

    before :each do
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
      cluster = user.home_cluster

      # auth user
      token = auth_user_hash(@admin_hash)

      # work
      get_json '/teamClusters', {}, {"token" => token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      res_cluster = resp_data["clusters"][0]
      expect(res_cluster["name"]).to eq @cluster.name
      expect(res_cluster["name"]).not_to eq cluster.name

    end

  end
end
