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

  describe "Stop active node" do
    before :each do
      # active node
      @node = create_node_active(@cluster)

    end

    it "for active node" do
      # work
      put_json '/nodes', {nodeID: @node.uid, command: 'stop'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      @node.reload

      expect(@node.status).to eq 'stopping'

    end


  end
end
