RSpec.describe "team info", :type => :request do
  before :each do
    #
    stub_create_cluster_all
  end

  describe 'get team info' do

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
      # auth main user
      token = auth_user_hash(@admin_hash)

      # work get cluster info not superadmin
      get_json '/teamInfo', {}, {"token" => token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      expect(resp_data["team"]["name"]).to eq @team.name
      expect(resp_data["team"]["isEnterprise"]).to eq (@team.is_enterprise==1)

    end

  end
end
