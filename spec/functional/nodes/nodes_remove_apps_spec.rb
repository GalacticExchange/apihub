RSpec.describe "Node remove - apps", :type => :request do

  before :each do
    #
    stub_create_user_all
    stub_create_cluster_all

    # create user with cluster
    @user, @cluster = create_user_and_cluster_onprem
  end


  describe 'remove apps' do
    before :each do
      # stub
      stub_create_node_all

      # active node
      @node = create_node_active(@cluster)

      # app
      # stub
      stub_create_app_all

      @app_library = get_random_library_app_not_hadoop
      @app_name = @app_library.name

      @app_settings = build_app_settings

      res_app = Gexcore::Applications::Service.install_application_by_user(@user, @app_name, @node.uid, @app_settings)

      @app = ClusterApplication.get_by_id(res_app.data[:application_id])


    end


    it 'remove app' do
      # stub rabbitmq operations
      stub_node_remove_rabbitmq

      #
      res = Gexcore::Nodes::Service.remove_node @node

      # check
      @node.reload

      #
      @app.reload

      expect(@app.status).to eq 'removed'

    end




  end

end
