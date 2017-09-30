RSpec.describe "Restart node", :type => :request do

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

  describe 'restart process' do

    it 'restart - OK' do
      # have active node
      @node = create_node_status_active(@cluster)
      @node_agent_token = @node.agent_token

      # restart
      put_json '/nodes', {nodeID: @node.uid, command: 'restart'}, {token: @token}

      #
      @node.reload
      expect(@node.status).to eq 'restarting'

      # gexd restarts node

      # gexd notify
      post_json '/notify', {nodeID: @node.uid, event: 'NODE_RESTARTED'}, {nodeAgentToken: @node_agent_token}

      # check
      @node.reload
      expect(@node.status).to eq 'active'

    end

    it 'restart error' do
      # have active node
      @node = create_node_status_active(@cluster)
      @node_agent_token = @node.agent_token

      # restart
      put_json '/nodes', {nodeID: @node.uid, command: 'restart'}, {token: @token}

      #
      @node.reload
      expect(@node.status).to eq 'restarting'

      # gexd restarts node - error there

      # gexd notify with error
      post_json '/notify', {nodeID: @node.uid, event: 'NODE_RESTART_ERROR'}, {nodeAgentToken: @node_agent_token}

      # check
      @node.reload
      expect(@node.status).to eq 'restart_error'


    end
  end







end
