RSpec.describe "Permissions to list share", :type => :request do

  describe 'list share' do

    before :each do

      # superadmin
      @id = 777
      # stub
      @superadmin_cluster = Cluster.new
      allow(@superadmin_cluster).to receive(:id).and_return(@id)

      @superadmin = double(User, :id => @id, :main_cluster_id => @superadmin_cluster.id, :group_id => Group.group_superadmin.id)
      @superadmin_ability = Gexcore::Myability.new(@superadmin)

      # admin
      @id = 888
      @admin = double(User, :id => @id, :main_cluster_id => @superadmin_cluster.id, :group_id => Group.group_admin.id)
      @admin_ability = Gexcore::Myability.new(@admin)

      # user
      @id = 999
      @user = double(User, :id => @id, :main_cluster_id => @superadmin_cluster.id, :group_id => Group.group_user.id)
      @user_ability = Gexcore::Myability.new(@user)

    end

    after :each do

    end


    it 'superadmin can list share' do
      #work
      expect(@superadmin_ability.can?(:shares_list, @superadmin_cluster)).to eq true
    end

    it 'admin can list share' do
      #work
      expect(@admin_ability.can?(:shares_list, @superadmin_cluster)).to eq true
    end

    it 'user cannot list share' do
      #work
      expect(@user_ability.can?(:shares_list, @superadmin_cluster)).to eq false
    end

  end

end



