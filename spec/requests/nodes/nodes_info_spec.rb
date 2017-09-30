RSpec.describe "Nodes", :type => :request do
  before :each do
    # stub
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    #
    @user, @cluster = create_user_and_cluster_onprem

    @username = @user.username

    # install node
    @node = create_node(@cluster)

    #
    @token = auth_token @user

  end

  after :each do

  end

  describe "GET /nodes/:uid/info" do

    it "node info" do
      # work
      get_json "/nodes/#{@node.uid}/info", {}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      expect(resp.status).to eq 200

      #
      expect(data['node']).to be_truthy

      #
      node = data['node']

      expect(node['id']).to be_truthy
      expect(node['name']).to be_truthy
      #expect(node['host']).to be_truthy
      expect(node['cluster']).to be_truthy
      expect(node['status']).to be_truthy
      expect(node['status_changed']).to be >0
      expect(node['hostType']).to be_truthy
      expect(node['nodeNumber']).to be_truthy

    end

    it 'get by NodeAgent' do
      # work
      get_json "/nodes/#{@node.uid}/info", {}, {nodeAgentToken: @node.agent_token}

      #
      resp = last_response
      data = response_json

      expect(resp.status).to eq 200

      #
      expect(data['node']).to be_truthy

      #
      node = data['node']

      expect(node['id']).to be_truthy
      expect(node['name']).to be_truthy
      expect(node['cluster']).to be_truthy
      expect(node['status']).to be_truthy
      expect(node['status_changed']).to be >0
      expect(node['hostType']).to be_truthy

    end

    describe 'alien node' do
      it 'alien node' do
        #
        @user2 = create_user_active

        # user2 tries access node from user1
        token2 = auth_token @user2

        get_json "/nodes/#{@node.uid}/info", {}, {token: token2}

        #
        resp = last_response
        data = response_json

        #
        expect(resp.status).to eq 403

        #
        expect(data['node']).to be_falsey

      end

      it 'not exists node' do
        # bad node uid
        node_uid = Gexcore::Nodes::Service.generate_uid

        # work
        get_json "/nodes/#{node_uid}/info", {}, {token: @token}

        #
        resp = last_response
        data = JSON.parse(resp.body)

        expect(resp.status).to eq 404

      end
    end


    describe 'for removed node' do

      before :each do
        # remove node
        # stub
        stub_remove_node_all

        # work
        delete_json "/nodes", {nodeID: @node.uid}, {token: @token}

      end


      it 'shows 404' do
        # work
        get_json "/nodes/#{@node.uid}/info", {}, {token: @token}

        #
        resp = last_response
        data = JSON.parse(resp.body)

        expect(resp.status).to eq 404
      end

    end


  end






end
