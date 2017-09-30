RSpec.describe "cluster info", :type => :request do
  before :each do
    @lib = Gexcore::Clusters::Service

    stub_create_user_all
    stub_create_cluster_all
  end

  describe 'info for the cluster' do
    before :each do
      # create user with cluster
      @admin, @cluster = create_user_active_and_create_cluster


      # stub can? => true
      stub_user_can_true

    end

    it 'get cluster info' do
      # work
      res = @lib.get_cluster_info_by_user(@admin, @cluster.uid)

      #
      expect(res.data).to be_truthy

      #
      cluster = res.data[:cluster]
      expect(cluster[:id]).to eq @cluster.uid
      expect(cluster[:name]).to eq @cluster.name
      expect(cluster[:domainname]).to eq @cluster.domainname
      expect(cluster[:status]).to be_truthy

      expect(cluster[:settings][:hadoopType]).to be_truthy
      #expect(cluster[:settings].keys.length).to eq 0


    end

    it 'get cluster info for the shared cluster' do
      # another user
      @user2 = create_user_active

      # share cluster
      Gexcore::Shares::Service.cluster_create_share(@cluster, @user2)

      #
      res = @lib.get_cluster_info_by_user(@user2, @cluster.uid)

      #
      expect(res.success?).to eq true

      cluster = res.data[:cluster]
      expect(cluster[:name]).to eq @cluster.name
      expect(cluster[:domainname]).to eq @cluster.domainname
    end

    it 'bad cluster id' do
      bad_uid = "#{@cluster.id}000"
      # work
      res = @lib.get_cluster_info_by_user(@admin, bad_uid)

      #
      expect(res.success?).to eq false
      expect(res.http_status).to eq 400

    end

  end

  describe 'get cluster info - permissions' do
    before :each do
      # create user with cluster
      @admin, @cluster = create_user_active_and_create_cluster

    end

    it 'no permissions' do
      #
      stub_user_can_false

      #
      res = @lib.get_cluster_info_by_user(@admin, @cluster.uid)

      #
      expect(res.success?).to eq false

    end

  end

end
