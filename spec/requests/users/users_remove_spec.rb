RSpec.describe "Users & users", :type => :request do
  before :each do

  end


  describe 'user remove' do

    before :each do
      #
      @admin_hash = build_user_hash
      @admin = create_user_active @admin_hash

    end

    after :each do

    end


    it "ok" do
      # prepare
      user_hash = build_user_hash
      victim = create_user_active_in_team(@admin.team_id, user_hash)

      # auth main user
      token = auth_user_hash(@admin_hash)

      # work
      delete_json '/users', {}, {"username" => user_hash[:username], "token" => token}

      #
      victim = User.get_by_username(user_hash[:username])

      expect(victim).to be nil

    end

  end
end
