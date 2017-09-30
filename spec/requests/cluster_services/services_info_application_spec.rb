RSpec.describe "Services for Application", :type => :request do

  before :each do
    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all
    stub_create_app_all


    # user
    @user_hash = build_user_hash
    @user = create_user_active_and_create_cluster(@user_hash)
    @user = User.get_by_username @user_hash[:username]

    # auth
    @token = auth_user_hash @user_hash


    # cluster
    @cluster = @user.home_cluster

    allow(@user).to receive(:can?).with(:manage, Cluster).and_return(true)

    # node
    @node = create_node(@cluster)

    # app
    #debug
    #@app_name = 'rocana'
    @app_name = ''

    if @app_name!=''
      @app_library = LibraryApplication.where(name: @app_name).first
    else
      @app_library = get_random_library_app_not_hadoop
    end

    @app_name = @app_library.name

    @app_settings = build_app_settings
    #@app_text_metadata = build_app_text_metadata
    @services = build_app_metadata_services

    @res_app = Gexcore::Applications::Service.install_application_by_user(@user, @app_name, @node.uid, @app_settings)
    @app = ClusterApplication.get_by_id(@res_app.data[:application_id])

  end

  after :each do

  end


  describe 'application' do
    it 'get /services' do
      #
      get_json '/services', {clusterID: @cluster.uid, applicationID: @app.uid}, {token: @token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      services = resp_data['services']
      expect(services.count).to be > 0

      services.each do |r|
        #expect(r['public_ip']).to be_truthy
        expect(r['name']).to be_truthy
        expect(r['nodeName']).to be_truthy
        expect(r['containerName']).to be_truthy
        expect(r['host']).to be_truthy
        expect(r['port']).to be_truthy
        expect(r['protocol']).to be_truthy
        expect(r['masterContainer']).to eq false
      end
    end



  end

end
