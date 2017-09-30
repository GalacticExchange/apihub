RSpec.describe "Notify uninstall application", :type => :request do
  before :each do

  end

  describe 'notify after uninstall' do
    before :each do
      # app - installing
      @app, @node, @user = create_app_uninstalling
      @cluster = @app.cluster

    end

    it 'notify application_uninstalled' do
      # pre-check
      expect(@app.status).to eq 'uninstalling'

      # work
      p = {
          applicationID: @app.uid,
          nodeID: @node.uid,
          clusterID: @cluster.uid,
      }
      res = Gexcore::NotificationService.notify('application_uninstalled', p)

      # check
      expect(res.success?).to eq true

      @app.reload

      expect(@app.status).to eq 'removed'

      # containers
      @app.containers.all.each do |container|
        expect(container.status).to eq 'removed'
      end

    end

    it 'notify application_uninstall_error' do
      # pre-check
      expect(@app.status).to eq 'uninstalling'

      # work
      p = {
          applicationID: @app.uid,
          nodeID: @node.uid,
          clusterID: @cluster.uid,
      }
      res = Gexcore::NotificationService.notify('application_uninstall_error', p)

      # check
      @app.reload

      expect(@app.status).to eq 'uninstall_error'

      # containers
      @app.containers.all.each do |container|
        expect(container.status).to eq 'uninstall_error'
      end

    end

  end


  describe 'uninstall for removed app' do
    before :each do
      # app
      @app, @node = create_app_active(@user)

      # remove
      Gexcore::Applications::Service.remove_application(@app)

      #
      stub_app_uninstall
    end

    it 'return 404' do
      # pre-check
      expect(@app.status).to eq 'removed'


      # work
      p = {
          applicationID: @app.uid,
          nodeID: @node.uid,
          clusterID: @app.cluster.uid,
      }
      res = Gexcore::NotificationService.notify('application_uninstalled', p)


      # check
      expect(res.http_status).to eq 404

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


