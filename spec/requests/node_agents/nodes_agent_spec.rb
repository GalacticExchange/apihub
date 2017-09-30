RSpec.describe "Node agent info", :type => :request do

  before :each do
    # stub
    stub_create_cluster_all
    stub_create_node_all

    #
    @user, @cluster = create_user_and_cluster_onprem

    # install node
    @node = create_node_active(@cluster)

    #
    #@token = auth_user_hash @user_hash
    @agent_token = @node.agent_token

  end

  after :each do

  end

  describe "Agent Info" do

    it "set agent info by agent" do
      req_data = {
          ip: "51.0.1.111",
          port: 12345,
      }


      # work - update agent info by agent
      post_json '/nodeAgentInfo', req_data, {nodeAgentToken: @agent_token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      # check data in DB
      @node.reload

      expect(@node.ip).to eq req_data[:ip]
      expect(@node.agent_port).to eq req_data[:port]

    end

    it "get agent info by agent" do
      req_data = {
          ip: "51.0.1.111",
          port: 12345,
      }

      # set info
      post_json '/nodeAgentInfo', req_data, {nodeAgentToken: @agent_token}


      # work - get info
      get_json '/nodeAgentInfo', {nodeID: @node.uid}, {nodeAgentToken: @agent_token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      #
      r = data['agent']
      expect(r['id']).to eq @node.uid
      expect(r['name']).to eq @node.name
      expect(r['ip']).to eq req_data[:ip]
      expect(r['port']).to eq req_data[:port]

    end

    describe 'get node agents' do
      before :each do
        # update info
        @agent1_data = {
            ip: "51.0.1.111",
            port: 12345,
        }

        @agent2_data = {
            ip: "51.0.1.150",
            port: 8080,
        }
      end

      it "get node agents by client" do
        @token = auth_token @user

        # update node1
        post_json '/nodeAgentInfo', @agent1_data, {nodeAgentToken: @agent_token}

        # node 2
        node2 = create_node_active(@cluster)
        post_json '/nodeAgentInfo', @agent2_data, {nodeAgentToken:   node2.agent_token}


        # work - get list of agents by node1
        get_json '/nodeAgents', {clusterID: @cluster.uid}, {token: @token}

        #
        resp = last_response
        data = JSON.parse(resp.body)

        #
        expect(resp.status).to eq 200

        #
        rows = data['agents']
        expect(rows.count).to eq 2

        ports_good = [@agent1_data[:port], @agent2_data[:port]]
        ips_good = [@agent1_data[:ip], @agent2_data[:ip]]

        ports = rows.map{|r| r['port']}
        ips = rows.map{|r| r['ip']}

        expect((ips-ips_good).count).to eq 0
        expect((ports-ports_good).count).to eq 0
      end


      it "get node agents by agent" do
        # update node1
        post_json '/nodeAgentInfo', @agent1_data, {nodeAgentToken: @agent_token}

        # node 2
        node2 = create_node_active(@cluster)
        post_json '/nodeAgentInfo', @agent2_data, {nodeAgentToken:   node2.agent_token}


        # work - get list of agents by node1
        get_json '/nodeAgents', {clusterID: @cluster.uid}, {nodeAgentToken: @agent_token}

        #
        resp = last_response
        data = JSON.parse(resp.body)

        #
        expect(resp.status).to eq 200

        #
        rows = data['agents']
        expect(rows.count).to eq 2

        ports_good = [@agent1_data[:port], @agent2_data[:port]]
        ips_good = [@agent1_data[:ip], @agent2_data[:ip]]

        ports = rows.map{|r| r['port']}
        ips = rows.map{|r| r['ip']}

        expect((ips-ips_good).count).to eq 0
        expect((ports-ports_good).count).to eq 0

      end

      it 'get agents - only joined' do
        skip
      end

    end

  end
end
