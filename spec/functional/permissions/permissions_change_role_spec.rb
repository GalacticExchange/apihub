RSpec.describe "Users & roles", :type => :request do

  describe 'user change role' do

    before :each do

      # superadmin
      @id = 777
      @superadmin_team = double(Team, :id => 500000)
      @superadmin = double(User, :id => @id, :team_id => @superadmin_team.id, :group_id => Group.group_superadmin.id)
      @superadmin_ability = Gexcore::Myability.new(@superadmin)

      # admin
      @id = 888
      @admin = double(User, :id => @id, :team_id => @superadmin_team.id, :group_id => Group.group_admin.id)
      @admin_ability = Gexcore::Myability.new(@admin)

      # user
      @id = 999
      @user = double(User, :id => @id, :team_id => @superadmin_team.id, :group_id => Group.group_user.id)
      @user_ability = Gexcore::Myability.new(@user)

    end

    after :each do
      #Apiservice::Service.del_user @username
    end


    describe 'general' do

      it 'victim user should be in the same cluster' do
        admin_team_2 = double(Team, :id => 500001)
        user_2 = double(User, :team_id => admin_team_2.id, :group_id => Group.group_superadmin.id)

        # work
        res = @superadmin_ability.can?(:change_role, [user_2, Group.group_user.id])
        #res = Gexcore::UsersService.set_role_by_admin(@user, @user.team_id, user_2.username, Group.group_user)

        #expect(res.http_status).to be 403
        expect(res).to be false
      end

      it "cannot change user to superadmin" do

        # work
        res = @superadmin_ability.can?(:change_role, [@user, Group.group_superadmin.id])

        #
        expect(res).to be false
      end

    end

    describe 'permissions' do

      describe 'superadmin permissions' do
        before :each do

        end

        describe 'false' do

          it "cannot change role of himself.  => returns false" do
            # work
            res = @superadmin_ability.can?(:change_role, [@superadmin, Group.group_user.id])

            expect(res).to be false
          end

        end

        describe 'true' do

          it "change role of admin to user" do
            # prepare
            id = 555
            user_2 = double(User, :id => id, :team_id => @superadmin_team.id, :group_id => Group.group_admin.id)

            # work
            res = @superadmin_ability.can?(:change_role, [user_2, Group.group_user.id])

            #
            expect(res).to be true
          end


          it "change user to admin" do
            # prepare
            id = 555
            user_2 = double(User, :id => id, :team_id => @superadmin_team.id, :group_id => Group.group_user.id)

            # work
            res = @superadmin_ability.can?(:change_role, [user_2, Group.group_admin.id])

            #
            expect(res).to be true
          end
        end
      end

      describe 'admin permissions' do
        describe 'false' do
          it "cannot change role of superadmin" do
            # work
            res = @admin_ability.can?(:change_role, [@superadmin, Group.group_admin.id])

            #
            expect(res).to be false
          end

          it "cannot change role of admin to user" do
            # prepare
            # another_admin
            id = 50
            admin = double(User, :id => @id, :team_id => @superadmin_team.id, :group_id => Group.group_admin.id)

            # work
            res = @admin_ability.can?(:change_role, [@superadmin, Group.group_user.id])

            #
            expect(res).to be false
          end
        end

        describe 'true' do

          it "can change role of user to admin" do
            # work
            res = @admin_ability.can?(:change_role, [@user, Group.group_admin.id])

            #
            expect(res).to be true
          end

        end

      end


      describe 'user permissions' do

        describe 'false' do

          it "user cannot change role of admin" do
            # work
            res = @user_ability.can?(:change_role, [@admin, Group.group_user.id])

            #
            expect(res).to be false

          end

          it "cannot change role of user to admin" do
            # prepare
            # another_user
            id = 55
            user = double(User, :id => @id, :team_id => @superadmin_team.id, :group_id => Group.group_user.id)
            # work
            res = @user_ability.can?(:change_role, [user, Group.group_admin.id])

            #
            expect(res).to be false
          end
        end

      end
    end

  end
end
