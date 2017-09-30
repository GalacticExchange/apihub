RSpec.describe "Start node", :type => :request do

  before :each do
    # stub
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    #
    @user, @cluster = create_user_active_and_create_cluster

    @token = auth_token @user

  end

  after :each do

  end

  describe "Start process" do
    before :each do

    end

    it 'process' do
      # have stopped node
      @node = create_node_status_stopped(@cluster)
      @node_agent_token = @node.agent_token

      # start
      put_json '/nodes', {nodeID: @node.uid, command: 'start'}, {token: @token}

      #
      @node.reload
      expect(@node.status).to eq 'starting'

      # gexd starts node

      # gexd notify
      post_json '/notify', {nodeID: @node.uid, event: 'NODE_STARTED'}, {nodeAgentToken: @node_agent_token}


      # check
      @node.reload
      expect(@node.status).to eq 'active'

    end

    it 'process - start_error' do
      # have stopped node
      @node = create_node_status_stopped(@cluster)
      @node_agent_token = @node.agent_token

      # start
      put_json '/nodes', {nodeID: @node.uid, command: 'start'}, {token: @token}

      #
      @node.reload
      expect(@node.status).to eq 'starting'

      # gexd starts node - error there

      # gexd notify
      post_json '/notify', {nodeID: @node.uid, event: 'NODE_START_ERROR'}, {nodeAgentToken: @node_agent_token}


      # check
      @node.reload
      expect(@node.status).to eq 'start_error'

    end

  end


end
