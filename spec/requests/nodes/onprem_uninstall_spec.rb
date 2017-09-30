RSpec.describe "Uninstall node", :type => :request do

  before :each do
    # stub
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all
    stub_remove_node_all

    #
    @user, @cluster = create_user_and_cluster_onprem

    @token = auth_token @user


  end

  after :each do

  end

  describe "notify NODE_UNINSTALLING" do

    context 'active node' do
      before :each do
        # active node
        @node = create_node_active(@cluster)


      end

      it "for active node" do
        # work
        post_json '/notify', {clusterID: @cluster.uid, nodeID: @node.uid, event: 'NODE_UNINSTALLING'}, {token: @token}

        #
        resp = last_response
        data = JSON.parse(resp.body)

        #
        expect(resp.status).to eq 200

        @node.reload

        expect(@node.uninstalling?).to eq true

      end


      it 'calls provision on master' do
        # expect
        expect(NodeUninstallProvisionMasterWorker).to receive(:perform_async).with(@node.id, anything).and_return true

        # work
        post_json '/notify', {clusterID: @cluster.uid, nodeID: @node.uid, event: 'NODE_UNINSTALLING'}, {token: @token}

      end
    end



    it 'for removed node' do
      # prepare
      node = create_node_status_removed(@cluster)
      expect(node.status).to eq 'removed'

      # work
      post_json '/notify', {clusterID: @cluster.uid, nodeID: node.uid, event: 'NODE_UNINSTALLING'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 404

      node.reload

      expect(node.removed?).to eq true

    end
  end

  describe "notify NODE_UNINSTALLED" do

    it "for uninstalling node" do
      # prepare
      node = create_node_status_uninstalling(@cluster)
      expect(node.status).to eq 'uninstalling'

      # provision remove_node.yml - OK
      Gexcore::Nodes::Provision.provision_master_uninstall_node(node.id)


      # do the work
      post_json '/notify', {clusterID: @cluster.uid, nodeID: node.uid, event: 'NODE_UNINSTALLED'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      # check node
      node.reload
      expect(node.status).to eq 'removed'

    end
  end

  describe "notify NODE_UNINSTALL_ERROR" do

    it 'for uninstalling node' do
      # prepare
      node = create_node_status_uninstalling(@cluster)
      expect(node.status).to eq 'uninstalling'


      # do the work
      post_json '/notify', {clusterID: @cluster.uid, nodeID: node.uid, event: 'NODE_UNINSTALL_ERROR'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      #
      node.reload

      expect(node.uninstall_error?).to eq true
    end


  end


end
