RSpec.describe "Remove node", :type => :request do

  before :each do
    # stub
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    #
    @user, @cluster = create_user_active_and_create_cluster

    #
    @token = auth_token @user

  end

  after :each do

  end


  describe 'remove process' do
    # see nodes_remove_spec.rb

  end



end
