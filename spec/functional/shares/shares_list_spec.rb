RSpec.describe "Shares list", :type => :request do
  before :each do
    @lib = Gexcore::Shares::Service

    #
    stub_create_user_all
    stub_create_cluster_all
  end

  describe 'list shares for the cluster' do
    before :each do
      # create user with cluster and team
      @admin, @cluster = create_user_and_cluster_onprem

      # another user and cluster
      @another_admin, @another_admin_cluster = create_user_and_cluster_onprem

      # stub can? => true
      stub_user_can_true
    end

    it 'get user shares list' do

      # share send to other users
      ss_01 = @lib.create_share_by_admin(@admin, @cluster, @another_admin.username)

      # work
      res = @lib.get_user_shares_list(@admin, @cluster.id)


      expect(res.data[:shares]).to be_truthy

      users = res.data[:shares]

      expect(users.count).to eq 1

      good_names = [@another_admin.username]
      bad_names = [@admin.username]


      users.each do |u|
        expect(good_names.include? u[:username]).to be true
        expect(bad_names.include? u[:username]).to be false
      end

    end

    it 'get clusters shares list' do
      # share send to other users
      ss_01 = @lib.create_share_by_admin(@admin, @cluster, @another_admin.username)

      # work
      res = @lib.get_clusters_share_list_for_user(@another_admin)


      expect(res.data[:clusters]).to be_truthy

      clusters = res.data[:clusters]

      expect(clusters.count).to eq 1

      good_names = [Cluster.where(id: @cluster.id).first.name]
      bad_names = ['some name', "poh sho"]


      clusters.each do |u|
        expect(good_names.include? u[:name]).to be true
        expect(bad_names.include? u[:name]).to be false
      end

    end


  end

end
