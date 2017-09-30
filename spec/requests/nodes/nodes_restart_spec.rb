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



  describe "Restart stopped node" do
    before :each do
      # stopped node
      @node = create_node_status_stopped(@cluster)

    end

    it "for stopped - ok" do
      # work
      put_json '/nodes', {nodeID: @node.uid, command: 'restart'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      @node.reload
      expect(@node.status).to eq 'restarting'
    end
  end


  describe "Restart active node" do
    before :each do
      # active node
      @node = create_node_active(@cluster)
    end


    it "ok" do
      # work
      put_json '/nodes', {nodeID: @node.uid, command: 'restart'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      # node status not changed
      @node.reload
      expect(@node.status).to eq 'restarting'

    end

  end


  describe "Restart removed node" do
    before :each do
      # removed node
      @node = create_node_status_removed(@cluster)
    end


    it 'removed node - error' do
      # work
      put_json '/nodes', {nodeID: @node.uid, command: 'restart'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 500

      # node status not changed
      @node.reload
      expect(@node.status).to eq 'removed'
    end

    
  end



end
