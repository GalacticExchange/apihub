RSpec.describe "Uninstall application", :type => :request do
  before :each do
    # user
    @user, @cluster = create_user_active_and_create_cluster

    #
    @token = auth_token @user


  end


  describe "uninstall application" do

    context 'active app' do
      before :each do
        # app
        @app, @node = create_app_active(@cluster)

        # stub
        stub_app_uninstall

      end


      it 'DB' do
        # work
        post_json "/applications/#{@app.uid}/uninstall", {}, {token: @token}

        #
        resp = last_response
        data = JSON.parse(resp.body)


        # app
        @app.reload
        #app = ClusterApplication.get_by_uid(@app.uid)
        app = @app

        expect(app.status).to eq 'uninstalling'

        # container
        app.containers.each do |container|
          expect(container.status).to eq 'uninstalling'
        end


      end
    end

    context 'removed app' do
      before :each do
        # app
        @app, @node = create_app_active(@cluster)

        # remove
        Gexcore::Applications::Service.remove_application(@app)

        #
        stub_app_uninstall

      end

      it 'DB' do
        # work
        post_json "/applications/#{@app.uid}/uninstall", {}, {token: @token}

        #
        resp = last_response
        data = JSON.parse(resp.body)


        # app
        @app.reload

        expect(@app.status).to eq 'removed'

        # container
        @app.containers.each do |container|
          expect(container.status).to eq 'removed'
        end


      end
    end


  end


  describe 'notify from gexd after uninstall' do
    before :each do
      # app
      @app, @node = create_app_uninstalling(@cluster)

    end


    it 'notify APPLICATION_UNINSTALLED' do
      # pre-check
      expect(@app.status).to eq 'uninstalling'


      # before
      @n_applications_old = ClusterApplication.w_not_deleted.count
      @n_containers_old = ClusterContainer.w_not_deleted.count

      # work
      post_json '/notify', {
          clusterID: @cluster.uid,
          nodeID: @node.uid,
          applicationID: @app.uid,
          event: 'APPLICATION_UNINSTALLED'
      }, {token: @token}


      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200


      #
      @app.reload

      # check
      expect(ClusterApplication.w_not_deleted.count).to eq @n_applications_old-1
      expect(ClusterContainer.w_not_deleted.count).to eq @n_containers_old-1

      expect(@app.status).to eq 'removed'

      # containers
      @app.containers.all.each do |container|
        expect(container.status).to eq 'removed'
      end

    end

    it 'notify APPLICATION_UNINSTALL_ERROR' do
      # pre-check
      expect(@app.status).to eq 'uninstalling'


      # work
      post_json '/notify', {clusterID: @cluster.uid, nodeID: @node.uid, applicationID: @app.uid, event: 'APPLICATION_UNINSTALL_ERROR'}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200


      #
      @app.reload

      # check
      expect(@app.status).to eq 'uninstall_error'

      # containers
      @app.containers.all.each do |container|
        expect(container.status).to eq 'uninstall_error'
      end

    end
  end


  describe 'notify from gexd for removed node' do
    before :each do
      # app
      @app, @node = create_app_active(@cluster)

      # remove
      Gexcore::Applications::Service.remove_application(@app)

      #
      stub_app_uninstall
    end


    it 'notify APPLICATION_UNINSTALLED' do
      # pre-check
      expect(@app.status).to eq 'removed'


      # work
      post_json '/notify', {
          clusterID: @cluster.uid,
          nodeID: @node.uid,
          applicationID: @app.uid,
          event: 'APPLICATION_UNINSTALLED'
      }, {token: @token}


      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 404

      #
      @app.reload

      # check
      expect(@app.status).to eq 'removed'

      # containers
      @app.containers.all.each do |container|
        expect(container.status).to eq 'removed'
      end

    end
  end

end


