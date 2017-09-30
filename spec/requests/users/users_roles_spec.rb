RSpec.describe "Users & roles", :type => :request do
  before :each do

  end


  describe 'user change role' do

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
      put '/users/roles', {"username" => user_hash[:username], "role" => Group.group_admin.name}, {"tokenId" => token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      # check
      expect(resp.status).to be 200

      #
      victim = User.get_by_username(user_hash[:username])

      expect(victim.group_id).to eq Group.group_admin.id

    end


    it "ERROR. current user is superadmin change role user on superadmin. if ok => returns error 403" do
      # prepare

      # user - admin
      victim = create_user_active_in_team(@admin.team_id)
      Gexcore::UsersService.set_user_role_in_team(victim, Group.group_admin.id)

      # auth main user
      token = auth_user_hash(@admin_hash)

      # work
      put '/users/roles', {"username" => victim.username, "role" => Group.group_superadmin.name}, {"tokenId" => token}

      #
      resp = last_response

      # expect
      expect(resp.status).to eq(403)
    end

  end
end
