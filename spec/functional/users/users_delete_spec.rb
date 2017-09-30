RSpec.describe "Delete user", :type => :request do

  describe 'del user from team' do

    before :each do
      # for user create
      @lib = Gexcore::UsersService
      #
      stub_create_user_all

      # create user with cluster
      @admin = create_user_active
      #
      @user = create_user_active_in_team(@admin.team_id)

    end

    after :each do

    end

    describe 'success' do

      before :each do
        stub_user_can_true
      end

      it 'ok' do
        # work
        res = @lib.delete_user_by_admin(@user.username, @admin)

        # check
        expect(res.http_status).to be 200

        user = User.find @user.id

        expect(user.deleted?).to be true

      end

      it 'delete user not see the team list' do
        # users
        user2 = create_user_active_in_team(@admin.team_id)
        user3 = create_user_active_in_team(@admin.team_id)

        # delete user
        res = @lib.delete_user_by_admin(@user.username, @admin)

        # work
        res = @lib.get_users_in_team(@admin)

        #
        expect(res.data[:users]).to be_truthy

        #
        users = res.data[:users]
        expect(users.count).to eq 3

        #
        good_names = [user2.username, user3.username, @admin.username]
        bad_names = [@user.username]

        #
        users.each do |u|
          expect(good_names.include? u[:username]).to be true
          expect(bad_names.include? u[:username]).to be false
        end
      end

      it 'user info not see the delete user' do
        # users
        user2 = create_user_active_in_team(@admin.team_id)
        user3 = create_user_active_in_team(@admin.team_id)

        # delete user
        res = @lib.delete_user_by_admin(@user.username, @admin)

        # delete user
        @lib.delete_user_by_admin(@user.username, @admin)

        # work
        res = @lib.get_user_info(@user.username)

        #
        expect(res.http_status).to eq 400

      end
    end

    describe 'errors' do

      it 'no permissions' do
        # stub can? => false
        stub_user_can_false

        res = @lib.delete_user_by_admin(@user.username, @admin)

        #
        expect(res.http_status).to be 403

      end
    end
  end
end


