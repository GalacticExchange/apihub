RSpec.describe "User roles", :type => :request do

  before :each do
    stub_create_user_all

  end

  describe 'set role in team' do
    before :each do

      # user
      @admin = create_user_active

    end

    after :each do

    end

    describe 'general' do

      it 'ok' do
        # prepare
        victim = create_user_active_in_team(@admin.team_id)

        # stub can? => true
        stub_user_can_true

        # work
        res = Gexcore::UsersService.set_role_by_admin(@admin, @admin.team, victim.username, Group.group_admin.name)

        #
        victim.reload

        # check
        expect(res.http_status).to be 200
        expect(victim.group_id).to eq Group.group_admin.id
      end

      it 'no permissions' do
        # prepare
        victim = create_user_active_in_team(@admin.team_id)

        # stub can? => false
        stub_user_can_false

        #work
        res = Gexcore::UsersService.set_role_by_admin(@admin, @admin.team, victim.username, Group.group_admin.name)

        # check
        expect(res.http_status).to be 403
        expect(victim.group_id).to eq Group.group_user.id
      end

      it "user not exist in DB" do
        unknown_username = generate_email

        # work
        res = Gexcore::UsersService.set_role_by_admin(@admin, @admin.team, unknown_username, Group.group_admin.name)

        #
        expect(res.http_status).to be 400

        # expectation
        # TODO: !!! check error message
      end


    end
  end
end


