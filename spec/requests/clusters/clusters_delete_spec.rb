RSpec.describe "Delete cluster", :type => :request do
  before :each do
    # stub
    stub_create_cluster_all


    #
    @user, @cluster = create_user_active_and_create_cluster

    # auth main user
    @token = auth_token @user
  end


  describe 'uninstall' do
    it 'add async task' do

    end
  end



end

