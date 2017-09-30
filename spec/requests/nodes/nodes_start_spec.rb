RSpec.describe "Start node", :type => :request do

  before :each do
    # stub
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    #
    @user, @cluster = create_user_active_and_create_cluster

    @token = auth_token @user

  end

  after :each do

  end


  describe "Start stopped node" do
    before :each do
      # stopped node
      @node = create_node_status_stopped(@cluster)

    end

    it "ok if role == admin or superadmin" do
      # work
      put_json '/nodes', {nodeID: @node.uid, command: 'start'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      @node.reload

      expect(@node.status).to eq 'starting'
    end

    it "bad if role == user" do
      # new user in our team
      @victim_hash = build_user_hash
      @victim = create_user_active_in_team(@user.team_id, @victim_hash)
      @victim_token = auth_user_hash @victim_hash


      # work
      put_json '/nodes', {nodeID: @node.uid, command: 'start'}, {token: @victim_token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 403

      @node.reload

      expect(@node.status).to eq 'stopped'
    end

  end

  describe 'start active node' do
    before :each do
      # active node
      @node = create_node_active(@cluster)

    end

    it "for active node - error" do
      # work
      put_json '/nodes', {nodeID: @node.uid, command: 'start'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 500

      @node.reload

      expect(@node.status).to eq 'active'

    end
  end

  describe 'start removed node' do
    before :each do
      # removed node
      @node = create_node_status_removed(@cluster)

    end

    it 'removed node - error' do
      # work
      put_json '/nodes', {nodeID: @node.uid, command: 'start'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 500

      @node.reload

      expect(@node.status).to eq 'removed'
    end

    
  end
end
