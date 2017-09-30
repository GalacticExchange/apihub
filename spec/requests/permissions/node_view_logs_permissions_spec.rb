RSpec.describe "Permissions to view node logs", :type => :request do

  describe 'Node Agent checks permissions for user' do

    before :each do
      # stub
      stub_create_cluster_all
      stub_create_node_all

      #
      @admin = create_user_active_and_create_cluster
      @cluster = @admin.home_cluster
      @team = @admin.team

      # install node
      @node = create_node(@cluster)

      #
      @agent_token = @node.agent_token
      @token = Gexcore::AuthService.get_new_token @admin

    end

    after :each do

    end

    it "admin of the team can" do

      get_json '/permissions/check/nodeViewLogs', {userToken: @token}, {nodeAgentToken: @agent_token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      expect(resp.status).to eq 200
    end

    it "admin of another team cannot" do
      # prepare
      user2 = create_user_active_and_create_cluster
      user2_token = Gexcore::AuthService.get_new_token user2

      # work
      get_json '/permissions/check/nodeViewLogs', {userToken: user2_token}, {nodeAgentToken: @agent_token}

      # check
      resp = last_response
      data = JSON.parse(resp.body)

      expect(resp.status).to eq 403
    end
  end
end
