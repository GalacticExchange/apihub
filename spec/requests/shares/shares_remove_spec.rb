RSpec.describe "shares remove", :type => :request do

  before :each do
    #
    stub_create_cluster_all

    @lib = Gexcore::Shares::Service
  end


  describe 'remove share' do

    before :each do

      # user - create cluster
      #install_cluster_stub_all

      #
      @admin_hash = build_user_hash
      @admin = create_user_active_and_create_cluster @admin_hash
      @cluster = @admin.home_cluster
      @team = Team.find(@cluster.team_id)
    end

    after :each do

    end

    it "ok" do
      # prepare
      user_hash = build_user_hash
      user = create_user_active_and_create_cluster user_hash

      # share create to user
      ss_01 = @lib.create_share_by_admin(@admin, @cluster, user.username)

      # check
      share = ClusterAccess.where(cluster_id: @cluster, user_id: user.id).first
      #
      expect(share).not_to be nil

      # auth user
      token = auth_user_hash(@admin_hash)

      # work
      delete_json '/shares', {}, {"username" => user.username, "token" => token}

      # check
      share = ClusterAccess.has_access?(@cluster.id, user.id)

      #
      expect(share).to be false

    end

  end
end
