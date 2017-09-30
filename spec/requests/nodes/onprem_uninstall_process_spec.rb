RSpec.describe "Uninstall node", :type => :request do

  before :each do
    # stub
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all
    stub_remove_node_all

    #
    @user, @cluster = create_user_active_and_create_cluster

    #
    @token = auth_token @user

  end

  after :each do

  end


  describe 'uninstall process' do

    it 'uninstall broken node' do
      # prepare node - start_error
      node = create_node_status_start_error(@cluster)
      expect(node.status).to eq 'start_error'


      # do the work


      # uninstalling
      post_json '/notify', {clusterID: @cluster.uid, nodeID: node.uid, event: 'NODE_UNINSTALLING'}, {token: @token}


      # wait...

      # notify uninstalled
      post_json '/notify', {clusterID: @cluster.uid, nodeID: node.uid, event: 'NODE_UNINSTALLED'}, {token: @token}

      node.reload

      # provision remove_node.yml
      Gexcore::Nodes::Provision.provision_master_uninstall_node(node.id)

      node.reload


      # check
      expect(node.status).to eq 'removed'

    end


    it 'uninstall removed node' do
      # prepare
      node = create_node_status_removed(@cluster)
      expect(node.status).to eq 'removed'

      # do the work
      stub_node_remove_rabbitmq

      # uninstalling
      post_json '/notify', {clusterID: @cluster.uid, nodeID: node.uid, event: 'NODE_UNINSTALLING'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 404

      node.reload
      expect(node.status).to eq 'removed'

      # wait... do smth on client

      # uninstalled
      post_json '/notify', {clusterID: @cluster.uid, nodeID: node.uid, event: 'NODE_UNINSTALLED'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 404

      #
      node.reload

      # check
      expect(node.status).to eq 'removed'

    end
  end




end
