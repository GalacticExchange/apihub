RSpec.describe "Delete shares", :type => :request do
  before :each do
    @lib = Gexcore::Shares::Service

    #
    stub_create_user_all
    stub_create_cluster_all
  end

  describe 'delete share' do
    before :each do

      # create user with cluster and team
      @admin, @admin_cluster = create_user_and_cluster_onprem

      #
      @another_admin, @another_admin_cluster = create_user_and_cluster_onprem

      # stub can? => true
      stub_user_can_true


    end

    it 'delete user from share' do

      # share send to other users
      ss_01 = @lib.create_share_by_admin(@admin, @admin_cluster, @another_admin.username)

      # find share user
      victim = @another_admin#User.get_by_username(as_03_username)
      # check
      share = ClusterAccess.where(cluster_id: @admin_cluster.id, user_id: victim.id).first
      #
      expect(share).not_to be nil

      # work
      res = @lib.delete_share_by_admin(@admin, @admin_cluster, @another_admin.username)

      # check
      share = ClusterAccess.where(cluster_id: @admin_cluster.id, user_id: victim.id).first

      #
      expect(share).to be nil

    end

  end

end
