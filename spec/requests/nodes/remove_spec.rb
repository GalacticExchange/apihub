RSpec.describe "Remove node", :type => :request do

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

  describe "remove node" do

    it "active node" do
      # active node
      node = create_node_active(@cluster)

      # work
      delete_json '/nodes', {nodeID: node.uid}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      node.reload

      expect(node.removed?).to eq true

    end

    it 'broken node' do
      # prepare
      node = create_node_status_start_error(@cluster)
      expect(node.status).to eq 'start_error'


      # work
      delete_json '/nodes', {nodeID: node.uid}, {token: @token}

      # check
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      node.reload

      expect(node.removed?).to eq true

    end


  end


end
