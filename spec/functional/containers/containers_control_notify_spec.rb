RSpec.describe "Notify container", :type => :request do

  before :each do
    @lib = Gexcore::Containers::Control

    # create user with cluster
    stub_create_user_all
    stub_create_cluster_all


    #
    @user, @cluster = create_user_and_cluster_onprem
  end

end

