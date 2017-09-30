RSpec.describe "Permissions to view cluster info", :type => :request do

  describe 'cluster info' do

    before :each do

      # superadmin
      @sacid = 7777
      # stub
      @superadmin_cluster = Cluster.new
      allow(@superadmin_cluster).to receive(:id).and_return(@sacid)

      # some cluster
      @scid = 1117
      @some_cluster = Cluster.new
      allow(@some_cluster).to receive(:id).and_return(@scid)

      # superadmin
      @suid = 7077
      @superadmin = double(User, :id => @suid, :main_cluster_id => @superadmin_cluster.id, :group_id => Group.group_superadmin.id)
      @superadmin_ability = Gexcore::Myability.new(@superadmin)

      # admin
      @aid = 8887
      @admin = double(User, :id => @aid, :main_cluster_id => @superadmin_cluster.id, :group_id => Group.group_admin.id)
      @admin_ability = Gexcore::Myability.new(@admin)

      # user
      @uid = 9997
      @user = double(User, :id => @uid, :main_cluster_id => @superadmin_cluster.id, :group_id => Group.group_user.id)
      @user_ability = Gexcore::Myability.new(@user)

      # some_user
      @sid = 4447
      @some_user = double(User, :id => @sid, :main_cluster_id => @some_cluster.id, :group_id => Group.group_user.id)
      @some_user_ability = Gexcore::Myability.new(@some_user)

    end

    after :each do

    end


    it 'superadmin can view cluster info her main cluster' do
      expect(@superadmin_ability.can?(:view_cluster_info, @superadmin_cluster)).to eq true
    end

    it 'admin can view cluster info her main cluster' do
      expect(@admin_ability.can?(:view_cluster_info, @superadmin_cluster)).to eq true
    end

    it 'user can view cluster info her main cluster' do
      expect(@user_ability.can?(:view_cluster_info, @superadmin_cluster)).to eq true
    end

#    it 'user cannot view alien cluster info' do
#      expect(@some_user_ability.can?(:view_cluster_info, @superadmin_cluster)).to eq false
#    end

    # Shared
    it 'shared user can view cluster info' do
      # stub _after_save method
      #ClusterAccess.any_instance.stub(:_after_save).and_return(true)

      # create share in DB
      #ClusterAccess.add!(@superadmin_cluster.id , @some_user.id)

      # stub has_access? method
      expect(ClusterAccess).to receive(:has_access?).with(@superadmin_cluster.id, @some_user.id).and_return(true)

      # work
      expect(@some_user_ability.can?(:view_cluster_info, @superadmin_cluster)).to eq true
    end

  end

end



