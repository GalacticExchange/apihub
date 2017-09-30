RSpec.describe "Notifications", :type => :request do

  before :each do

    stub_create_user_all

    #
    @user_hash = build_user_hash
    @user = create_user_active_and_create_cluster(@user_hash)


    @username = @user_hash[:username]
    @pwd = @user_hash[:password]

    #
    @user = User.get_by_username @username

    @cluster = @user.home_cluster

  end

  after :each do

  end

  describe "notify node_installed" do

    before :each do
      # install node
      stub_create_node_all

      @sysinfo = build_sysinfo

      @node = create_node(@cluster)

    end


    it "ok" do
      # auth
      token = auth_user @username, @pwd

      # work
=begin
"params":{"description":"Node was installed successfully","clusterID":"11111111",
"event":"NODE_INSTALLED","nodeID":"1531891414240217"
=end
      data = {event: 'NODE_INSTALLED', description: 'Node was installed successfully', clusterID: @cluster.uid, nodeID: @node.uid}

      post_json '/notify', data, {"token" => token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      # expectation
      expect(resp.status).to eq 200

    end
  end


  describe 'notify by node agent' do
    before :each do
      # install node
      stub_create_node_all

      @sysinfo = build_sysinfo

      @node = create_node(@cluster)

    end


    it "ok" do
      # auth
      agent_token = @node.agent_token

      data = {event: 'NODE_INSTALLED', description: 'Smth happened with the node', clusterID: @cluster.uid, nodeID: @node.uid}

      post_json '/notify', data, {"nodeAgentToken" => agent_token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      # expectation
      expect(resp.status).to eq 200

    end

    it 'bad agent token' do
      # auth
      agent_token = @node.agent_token+'000'

      data = {event: 'NODE_INSTALLED', description: 'Smth happened with the node', clusterID: @cluster.uid, nodeID: @node.uid}

      post_json '/notify', data, {"nodeAgentToken" => agent_token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      # expectation
      expect(resp.status).to eq 403

    end
  end
end
