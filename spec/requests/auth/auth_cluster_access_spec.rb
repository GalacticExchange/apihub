RSpec.describe "Auth Cluster Access", :type => :request do
  before :each do
    # stub
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    #
    @user_hash = build_user_hash
    @user, @cluster = create_user_and_cluster_onprem({},@user_hash)

  end


  describe 'auth cluster access' do
    before :each do
      #
      @token = auth_user_hash @user_hash

      @hadoop_master_hostname = Gexcore::AppHadoop::MasterContainer.calc_hostname('hadoop', @cluster)

    end


    it 'ok' do
      # work
      get_json '/auth_access_cluster', {token: @token, username: @user_hash[:username], hostname: @hadoop_master_hostname}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      # check
      expect(resp.status).to eq 200

      expect(resp_data['access']).to eq '1'
      expect(resp_data['username']).to eq @user_hash[:username]
      expect(resp_data['teamName']).to eq @user_hash[:teamname]
    end

    it 'ok for team member' do

    end

    it 'invalid token' do
      # work
      bad_token = @token+'111'
      get_json '/auth_access_cluster', {token: bad_token, username: @user_hash[:username], hostname: @hadoop_master_hostname}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      # check
      expect(resp.status).to eq 200

      expect(resp_data['access']).to eq '0'
    end

  end

  describe 'access alien cluster' do
    before :each do
      # cluster1 container
      @hadoop_master_hostname = Gexcore::AppHadoop::MasterContainer.calc_hostname('hadoop', @cluster)

      #
      @user2_hash = build_user_hash
      @user2, @cluster2 = create_user_and_cluster_onprem({}, @user2_hash)

      # give access to cluster1 for user2
      Gexcore::Shares::Service.cluster_create_share(@cluster, @user2)


    end

    it 'ok - shared cluster' do
      # pre check
      expect(ClusterAccess.has_access?(@cluster.id, @user2.id)).to eq true

      #
      @user2_token = auth_user_hash @user2_hash

      get_json '/auth_access_cluster', {token: @user2_token, username: @user2_hash[:username], hostname: @hadoop_master_hostname}


      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      # check
      expect(resp.status).to eq 200

      expect(resp_data['access']).to eq '1'
      expect(resp_data['username']).to eq @user2_hash[:username]
      expect(resp_data['teamName']).to eq @user2_hash[:teamname]


    end

    it 'no access' do
      #
      @user3_hash = build_user_hash
      @user3 = create_user_active_and_create_cluster(@user3_hash)

      #
      token = auth_user_hash @user3_hash

      get_json '/auth_access_cluster', {token: token, username: @user3_hash[:username], hostname: @hadoop_master_hostname}


      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      # check
      expect(resp.status).to eq 200

      expect(resp_data['access']).to eq '0'

    end

  end
end

