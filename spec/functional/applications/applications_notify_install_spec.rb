RSpec.describe "Notify for installing application", :type => :request do
  before :each do

  end

  describe 'notify from gexd after install' do
    before :each do
      # app - installing
      @app, @node, @user = create_app_installing
      @cluster = @app.cluster

    end

    it 'notify application_installed' do
      # pre-check
      expect(@app.status).to eq 'installing'

      # work
      p = {
          applicationID: @app.uid,
          nodeID: @node.uid,
          clusterID: @cluster.uid,
      }
      res = Gexcore::NotificationService.notify('application_installed', p)

      # check
      expect(res.success?).to eq true

      @app.reload

      expect(@app.status).to eq 'active'

      # containers
      @app.containers.all.each do |container|
        expect(container.status).to eq 'active'
      end

    end

    it 'notify application_install_error' do
      # pre-check
      expect(@app.status).to eq 'installing'

      # work
      p = {
          applicationID: @app.uid,
          nodeID: @node.uid,
          clusterID: @cluster.uid
      }
      res = Gexcore::NotificationService.notify('application_install_error', p)

      # check
      @app.reload

      expect(@app.status).to eq 'install_error'

      # containers
      @app.containers.all.each do |container|
        expect(container.status).to eq 'install_error'
      end

    end

  end


end


