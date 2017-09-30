RSpec.describe "Notify Node", :type => :request do

  before :each do
    #
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

  describe "Notify NODE_INSTALLED for installing node" do
    before :each do
      @node = create_node(@cluster)
    end

    it "ok - starting" do
      # precheck
      expect(@node.status).to eq 'installing'

      # work
      post_json '/notify', {clusterID: @cluster.uid, nodeID: @node.uid, event: 'NODE_INSTALLED'}, {token: @token}

      #
      resp = last_response
      data = response_json

      #
      expect(resp.status).to eq 200

      @node.reload
      expect(@node.status).to eq 'starting'

    end



  end

  describe "Notify NODE_INSTALL_ERROR for installing node" do

    before :each do
      #
      @node = create_node(@cluster)


    end

    it 'ok' do
      # pre check
      expect(@node.status).to eq 'installing'

      # work
      post_json '/notify', {clusterID: @cluster.uid, nodeID: @node.uid, event: 'NODE_INSTALL_ERROR'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      @node.reload
      expect(@node.status).to eq 'install_error'
    end
  end

end
