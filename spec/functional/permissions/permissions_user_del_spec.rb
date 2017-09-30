RSpec.describe "Permissions to delete user", :type => :request do

  describe 'del user in team' do

    before :each do
      # superadmin
      @id = 777
      @superadmin_team = double(Team, :id => 500000)
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
    end

    after :each do

    end

    describe 'superadmin ability' do
      it 'superadmin can delete user' do

        res = @superadmin_ability.can?(:user_del, @user)

        # work
        expect(res).to be true

      end

      it 'superadmin can delete any admin' do

        expect(@superadmin_ability.can?(:user_del, @admin)).to eq true

      end

      it 'superadmin cannot delete herself' do
        # work
        expect(@superadmin_ability.can?(:user_del, @superadmin)).to eq false

      end

      it 'superadmin cannot delete user from another cluster' do
        # prepare
        user = User.new
        # stub
        id = 101
        allow(user).to receive(:id).and_return(id)
        allow(user).to receive(:team_id).and_return(11)
        allow(user).to receive(:group_id).and_return(Group.group_user.id)

        # work
        res = @superadmin_ability.can?(:user_del, user)

        expect(res).to be false
      end
    end

    describe 'admin ability' do
        it 'admin can delete user' do
        # work
        expect(@admin_ability.can?(:user_del, @user)).to eq true

      end

      it 'admin cannot delete any admin' do
        # prepare
        admin = User.new
        # stub
        id = 102
        allow(admin).to receive(:id).and_return(id)
        allow(admin).to receive(:team_id).and_return(@superadmin_team.id)
        allow(admin).to receive(:group_id).and_return(Group.group_admin.id)

        expect(@admin_ability.can?(:user_del, admin)).to eq false
      end
    end

    describe 'user ability' do
      it 'user cannot delete any user' do
        # prepare
        user = User.new
        # stub
        id = 101
        allow(user).to receive(:id).and_return(id)
        allow(user).to receive(:team_id).and_return(@superadmin_team.id)
        allow(user).to receive(:group_id).and_return(Group.group_user.id)

        expect(@user_ability.can?(:user_del, user)).to eq false
      end
    end

  end

end



