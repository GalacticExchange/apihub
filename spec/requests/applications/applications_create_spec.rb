RSpec.describe "Create application", :type => :request do
  before :each do
    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    # user
    @user, @cluster = create_user_active_and_create_cluster

    # node
    @node = create_node(@cluster)

    # app
    @app_library = get_random_library_app_not_hadoop
    @app_name = @app_library.name

    @app_settings = build_app_settings

    # auth
    @token = auth_token @user
  end


  describe "create application" do
    before :each do
      stub_create_app_all

    end


    it 'DB' do
      # before
      @n_applications_old = ClusterApplication.count
      @n_containers_old = ClusterContainer.count

      # work
      post_json '/applications', {applicationName: @app_name, nodeID: @node.uid}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)


      # check
      expect(ClusterApplication.count).to eq @n_applications_old+1
      expect(ClusterContainer.count).to eq @n_containers_old+1

      # app
      app = ClusterApplication.get_by_uid(data['applicationID'])

      expect(data['name']).to be_truthy

      expect(app.name).to eq data['name']
      expect(app.library_application_id).to eq @app_library.id
      expect(app.cluster_id).to eq @cluster.id
      expect(app.status).to eq 'installing'

      settings = app.settings
      expect(settings).to be_truthy

      # container
      container = app.containers.last

      expect(container.basename).to eq @app_name
      expect(container.name).to eq "#{@app_name}-#{@node.name}"
      expect(container.hostname).to be_truthy
      expect(container.cluster_id).to eq @cluster.id
      expect(container.node_id).to eq @node.id
      expect(container.is_master).to eq false
      expect(container.status).to eq 'installing'

    end

  end


  describe 'notify after installApplication' do
    before :each do
      stub_create_app_all

      # create app
      post_json '/applications', {applicationName: @app_name, nodeID: @node.uid}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      @app = ClusterApplication.get_by_uid(data['applicationID'])

    end


    it 'notify application_installed' do
      # pre-check
      expect(@app.status).to eq 'installing'

      # work
      post_json '/notify', {clusterID: @cluster.uid, nodeID: @node.uid, applicationID: @app.uid, event: 'APPLICATION_INSTALLED'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      @app.reload
      expect(@app.status).to eq 'active'

      # containers
      containers = @app.containers.all

      containers.each do |container|
        expect(container.status).to eq 'active'
      end

    end
  end
end


