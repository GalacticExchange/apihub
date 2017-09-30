RSpec.describe "Nodes list", :type => :request do
  before :each do
    # stub
    stub_create_cluster_all
    stub_create_node_all

    #
    @user1, @cluster1 = create_user_active_and_create_cluster

    # nodes
    @node1_1 = create_node(@cluster1)
    @node1_2 = create_node(@cluster1)
    @cluster1_uids = [@node1_1.uid, @node1_2.uid]


    # cluster 2, node in cluster 2
    @user2, @cluster2 = create_user_active_and_create_cluster
    @node2_1 = create_node(@cluster2)
    @cluster2_uids = [@node2_1.uid]


    #
    @token = auth_token @user1
  end

  after :each do

  end

  describe "list" do

    it "info" do
      # work
      get_json '/nodes', {clusterID: @cluster1.uid}, {token: @token}

      #
      resp = last_response
      resp_data = response_json
      nodes = resp_data['nodes']

      #
      expect(nodes.length).to be > 0

      uids = nodes.map{|r| r['id']}
      uids.each do |uid|
        expect(@cluster1_uids).to include(uid)
        expect(@cluster2_uids).not_to include(uid)
      end

      #
      node = nodes[0]

      expect(node['id']).to be_truthy
      expect(node['name']).to be_truthy
      expect(node['status']).to be_truthy
      expect(node['state']).to be_nil
      expect(node['status_changed']).to be_truthy
    end

    it 'with state' do
      # work
      get_json '/nodes', {clusterID: @cluster1.uid, mode: 'state'}, {token: @token}

      #
      resp = last_response
      resp_data = response_json
      nodes = resp_data['nodes']

      #
      expect(nodes.length).to be > 0

      # check list
      uids = nodes.map{|r| r['id']}
      uids.each do |uid|
        expect(@cluster1_uids).to include(uid)
        expect(@cluster2_uids).not_to include(uid)
      end

      #
      node = nodes[0]

      expect(node['id']).to be_truthy
      expect(node['name']).to be_truthy
      expect(node['status']).to be_truthy
      expect(node['state']).to be_truthy
      expect(node['status_changed']).to be_truthy

    end

  end


end
