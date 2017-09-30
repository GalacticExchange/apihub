RSpec.describe "Share cluster", :type => :request do
  before :each do
    @lib = Gexcore::Shares::Service

    #
    stub_create_user_all
    stub_create_cluster_all
  end

  describe 'send share' do

    before :each do
      # create user with cluster
      @admin, @cluster = create_user_and_cluster_onprem

      # other users
      @admin_in_another_team, @cluster2 = create_user_and_cluster_onprem
      @user_in_another_team = create_user_active_in_team(@admin_in_another_team.team_id)

    end

    after :each do
      #Apiservice::Service.del_user @username
    end

    describe 'success' do
      it 'ok  - response' do
        # stub can? => true
        stub_user_can_true

        # work
        res = @lib.create_share_by_admin(@admin, @cluster, @user_in_another_team.username)

        #
        expect(res.http_status).to be 200
      end

      it 'data in DB' do
        # stub can? => true
        stub_user_can_true

        #
        count = ClusterAccess.count

        # work
        res = @lib.create_share_by_admin(@admin, @cluster, @user_in_another_team.username)

        # check
        @admin.reload
        @user_in_another_team.reload

        #
        expect(ClusterAccess.count).to eq(count + 1)

        #
        row_access = ClusterAccess.where(:cluster_id => @cluster.id).last

        expect(row_access).not_to be_nil
        expect(row_access.user_id).to eq @user_in_another_team.id

      end
    end


    describe 'errors' do

      it 'user not exists in DB' do
        # prepare
        another_username = generate_username

        # work
        stub_user_can_true

        res = @lib.create_share_by_admin(@admin, @cluster, another_username)

        #
        expect(res.http_status).to be 400

      end

      it 'user already has access' do
        # stub can? => true
        stub_user_can_true

        # prepare
        @lib.create_share_by_admin(@admin, @cluster, @user_in_another_team.username)


        # work
        res = @lib.create_share_by_admin(@admin, @cluster, @user_in_another_team.username)

        #
        expect(res.http_status).to be 400
      end

    end

  end

end


