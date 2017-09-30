RSpec.describe "Permissions to change info team", :type => :request do

  describe 'change info team' do

    before :each do
      # superadmin
      @id = 777
      @superadmin_team = Team.new
      allow(@superadmin_team).to receive(:id).and_return(@id)


      @superadmin = User.new

      # stub
      allow(@superadmin).to receive(:id).and_return(@id)
      allow(@superadmin).to receive(:team_id).and_return(@superadmin_team.id)
      allow(@superadmin).to receive(:group_id).and_return(Group.group_superadmin.id)

      #@superadmin = double(User, :id => @id, :team_id => @superadmin_team.id, :group_id => Group.group_superadmin.id)
      @superadmin_ability = Gexcore::Myability.new(@superadmin)

      # admin
      @id = 888
      @admin = User.new

      # stub
      allow(@admin).to receive(:id).and_return(@id)
      allow(@admin).to receive(:team_id).and_return(@superadmin_team.id)
      allow(@admin).to receive(:group_id).and_return(Group.group_admin.id)

      #@admin = double(User, :id => @id, :team_id => @superadmin_team.id, :group_id => Group.group_admin.id)
      @admin_ability = Gexcore::Myability.new(@admin)

      # user
      @id = 999
      @user = User.new

      # stub
      allow(@user).to receive(:id).and_return(@id)
      allow(@user).to receive(:team_id).and_return(@superadmin_team.id)
      allow(@user).to receive(:group_id).and_return(Group.group_user.id)

      #@user = double("user2", :id => @id, :team_id => @superadmin_team.id, :group_id => Group.group_user.id)
      @user_ability = Gexcore::Myability.new(@user)

      # another team
      @id = 12345
      @another_team = Team.new
      allow(@another_team).to receive(:id).and_return(@id)
    end

    after :each do

    end

    describe 'can' do

      describe 'superadmin ability' do
        it 'superadmin can change info his oun team' do

          res = @superadmin_ability.can?(:change_team, @superadmin_team)

          # work
          expect(res).to be true

        end

      end

      describe 'admin ability' do
        it 'admin can change info his oun team' do

          res = @admin_ability.can?(:change_team, @superadmin_team)

          # work
          expect(res).to be true

        end

      end

      describe 'user ability' do
        it 'user cannot change info his oun team' do

          res = @user_ability.can?(:change_team, @superadmin_team)

          # work
          expect(res).to be false

        end
      end

    end

    describe "cannot" do

      describe 'superadmin ability' do
        it 'superadmin can change another team' do

          res = @superadmin_ability.can?(:change_team, @another_team)

          # work
          expect(res).to be false

        end

      end

      describe 'admin ability' do
        it 'admin can change another team' do

          res = @admin_ability.can?(:change_team, @another_team)

          # work
          expect(res).to be false

        end

      end

      describe 'user ability' do
        it 'user can change another team' do

          res = @user_ability.can?(:change_team, @another_team)

          # work
          expect(res).to be false

        end
      end

    end

  end

end



