RSpec.describe "users share list for cluster", :type => :request do
  before :each do
    # stub
    stub_create_cluster_all

  end

  describe 'get share users list for cluster' do

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

      # count
      count = ClusterAccess.count

      # auth user
      token = auth_user_hash(@admin_hash)

      # share create to user
      post_json '/shares', {"username" => user.username}, {"token" => token}

      # work get users for cluster
      get_json '/userShares', {}, {"token" => token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      share = resp_data["data"]["shares"][0]
      expect(share["firstName"]).to eq user_hash[:firstname]
      expect(share["lastName"]).to eq user_hash[:lastname]
      expect(share["username"]).to eq user_hash[:username]
      #
      expect(ClusterAccess.count).to eq (count + 1)


    end

  end
end
