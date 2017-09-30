RSpec.describe "Get cluster info", :type => :request do
  before :each do
    # stub
    stub_create_cluster_all
  end

  describe 'cluster_info' do
    before :each do
      @user, @cluster = create_user_active_and_create_cluster

      # auth main user
      @token = auth_token @user

    end

    it 'get cluster info' do
      get_json '/clusterInfo', {clusterID: @cluster.uid}, {"token" => @token}

      #
      resp = last_response
      resp_data = response_json

      cluster = resp_data['cluster']

      #
      @cluster.reload

      #
      expect(cluster['hadoopApplicationID']).to be_truthy


      # settings
      settings = cluster['settings']
      expect(settings.keys.count).to be >0
      settings.each do |k, v|
        expect(Cluster::OPTIONS.keys).to include k
      end
      #Cluster.OPTI.each do |opt, v|
      #  expect(settings[opt.to_s]).not_to be_nil
      #  expect(settings[opt.to_s]).to eq v
      #end

    end
  end
end
