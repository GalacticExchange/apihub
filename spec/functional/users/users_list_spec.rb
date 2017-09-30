RSpec.describe "Shares list", :type => :request do
  before :each do
    @lib = Gexcore::UsersService

    #
    stub_create_user_all

  end

  describe 'list shares for the cluster' do
    before :each do


      # stub can? => true
      stub_user_can_true
    end

    it 'get user team list' do
      # create user
      @admin = create_user_active

      # create user in team
      @user = create_user_active_in_team(@admin.team_id)

      # add more users to team
      user2 = create_user_active_in_team(@admin.team_id)
      user3 = create_user_active_in_team(@admin.team_id)

      # work
      res = @lib.get_users_in_team(@admin)

      expect(res.data[:users]).to be_truthy

      users = res.data[:users]

      expect(users.count).to eq 4

      good_names = [user2.username, user3.username, @admin.username, @user.username]
      bad_names = ["petrosyan"]

      users.each do |u|
        expect(good_names.include? u[:username]).to be true
        expect(bad_names.include? u[:username]).to be false
      end

    end

  end

end
