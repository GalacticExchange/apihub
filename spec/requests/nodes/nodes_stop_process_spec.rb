RSpec.describe "Stop node", :type => :request do

  before :each do
    # stub
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    #
    @user, @cluster = create_user_active_and_create_cluster

    #
    @token = auth_token @user

  end

  after :each do

  end


  describe "Stop process" do
    before :each do

    end

    it 'process' do
      # have active node
      @node = create_node_status_active(@cluster)
      @node_agent_token = @node.agent_token

      # start
      put_json '/nodes', {nodeID: @node.uid, command: 'stop'}, {token: @token}

      #
      @node.reload
      expect(@node.status).to eq 'stopping'

      # gexd stops node

      # gexd notify
      post_json '/notify', {nodeID: @node.uid, event: 'NODE_STOPPED'}, {nodeAgentToken: @node_agent_token}


      # check
      @node.reload
      expect(@node.status).to eq 'stopped'

    end

    it 'process - stop_error' do
      # have active node
      @node = create_node_status_active(@cluster)
      @node_agent_token = @node.agent_token

      # start
      put_json '/nodes', {nodeID: @node.uid, command: 'stop'}, {token: @token}

      #
      @node.reload
      expect(@node.status).to eq 'stopping'

      # gexd stops node - error there

      # gexd notify
      post_json '/notify', {nodeID: @node.uid, event: 'NODE_STOP_ERROR'}, {nodeAgentToken: @node_agent_token}


      # check
      @node.reload
      expect(@node.status).to eq 'stop_error'

    end

  end
end
