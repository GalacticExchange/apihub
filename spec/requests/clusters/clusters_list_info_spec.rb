RSpec.describe "cluster info", :type => :request do

  describe 'get cluster info' do

    before :each do
      # stub
      stub_create_cluster_all

      #
      @admin, @cluster = create_user_active_and_create_cluster

    end

    after :each do

    end

    it 'get /teamClusters' do
      # auth main user
      token = auth_token(@admin)

      # work get cluster info not superadmin
      get_json '/teamClusters', {}, {"token" => token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      cluster = resp_data['clusters'][0]
      expect(cluster["id"]).to eq @cluster.uid
      expect(cluster["name"]).to eq @cluster.name
      expect(cluster["domainname"]).to eq @cluster.domainname
      expect(cluster["status"]).not_to be_nil

    end

    it "get /clusterInfo" do
      # prepare
      token = auth_token(@admin)

      # work
      get_json '/clusterInfo', {clusterID: @cluster.uid}, {"token" => token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      cluster = resp_data["cluster"]
      expect(cluster["id"]).to eq @cluster.uid
      expect(cluster["name"]).to eq @cluster.name
      expect(cluster["domainname"]).to eq @cluster.domainname
      expect(cluster["status"]).to be_truthy
    end

  end
end
