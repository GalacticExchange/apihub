RSpec.describe "Permissions to send invitation", :type => :request do

  describe 'send invitation' do

    before :each do

      # superadmin
      @id = 777
      # stub
      @superadmin_team = Team.new
      allow(@superadmin_team).to receive(:id).and_return(@id)

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

    end


    it 'superadmin can send invitation' do
      #work
      expect(@superadmin_ability.can?(:send_inv, @superadmin_team)).to eq true
    end

    it 'admin can send invitation' do
      #work
      expect(@admin_ability.can?(:send_inv, @superadmin_team)).to eq true
    end

    it 'user cannot send invitation' do
      #work
      expect(@user_ability.can?(:send_inv, @superadmin_team)).to eq false
    end

  end

end



