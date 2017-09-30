RSpec.describe "Create AppHub application", :type => :request do
  before :each do
    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    # create user with cluster
    @user, @cluster = create_user_and_cluster_onprem

    allow(@user).to receive(:can?).with(:manage, Cluster).and_return(true)

    # node
    @node = create_node(@cluster)

    # app
    #debug
    app_id = nil

    @apphub_app = app_id ? Gexcore::Apphub::Service.get_by_id(app_id) : get_random_apphub_app

    @app_name = @apphub_app['name']
    @app_id = @apphub_app['id']

    @app_settings = build_apphub_settings(@apphub_app)
    @services = @apphub_app['services']
  end

  describe "create application" do
    before :each do

      # stub
      stub_create_app_all

    end


    it 'DB' do
      # before
      @n_applications_old = ClusterApplication.count
      @n_containers_old = ClusterContainer.count


      # work
      res = Gexcore::Applications::Service.install_application_by_user(@user, @app_id, @node.uid, @app_settings,true)

      # check
      expect(res.success?).to eq true

      expect(ClusterApplication.count).to eq @n_applications_old+1
      expect(ClusterContainer.count).to eq @n_containers_old+1

      # app
      app = ClusterApplication.get_by_id(res.data[:application_id])

      new_app_name = "#{@app_name.downcase.gsub('-','_')}_#{app.uid}"

      #expect(app.name).to eq @app_name
      expect(app.uid).to be_truthy

      expect(app.external).to eq true
      expect(app.library_application_id).to eq @apphub_app['id']
      expect(app.cluster_id).to eq @cluster.id
      expect(app.status).to eq 'installing'

      app.name.should_not include("-")

      settings = app.settings
      expect(settings).to be_truthy

      # container
      container = ClusterContainer.get_by_id(res.data[:container_id])

      expect(container.uid).to be_truthy
      expect(container.basename).to eq new_app_name
      expect(container.name).to eq "#{new_app_name}-#{@node.name}"
      expect(container.hostname).to eq "#{new_app_name}-#{@node.name}.gex"

      expect(container.cluster_id).to eq @cluster.id
      expect(container.node_id).to eq @node.id
      expect(container.is_master).to eq false
      expect(container.status).to eq 'installing'

      # services
      services = container.services
      services_good_names = @services.keys

      services.each do |service|
        expect(services_good_names).to include service.name
      end

    end

    it 'generate config.json' do
      # work
      #res = Gexcore::Applications::Service.install_application(nil, @app_name, @node, @app_settings)
      res = Gexcore::Applications::Service.install_application_by_user(@user, @app_id, @node.uid, @app_settings,true)

      # check
      expect(res.success?).to eq true

      container = ClusterContainer.get_by_id(res.data[:container_id])
      app = ClusterApplication.get_by_id(res.data[:application_id])

      filename = Gexcore::Applications::Service.config_for_application_filename(container, app)

      text = File.read(filename)
      config_data = JSON.parse(text)

      config_data['launch_options'].should_not be_nil
      config_data['download_link'].should_not be_nil

      expect(config_data['metadata'].is_a?(Hash)).to eq true
      expect(config_data['services'].is_a?(Hash)).to eq true

    end

=begin

    it 'provision master async' do
      #
      expect(AppProvisionMasterWorker).to receive(:perform_async).and_return true

      # work
      res = Gexcore::Applications::Service.install_application_by_user(@user, @app_name, @node.uid, @app_settings)

    end

    it 'provision master with ansible script - add_app.yml' do

      # work
      res = Gexcore::Applications::Service.install_application_by_user(@user, @app_name, @node.uid, @app_settings)

      app = ClusterApplication.get_by_id(res.data[:application_id])

      # check
      expect(Gexcore::Provision::Service).to receive(:run_script_ansible).with('add_app.yml', anything)

      # run from queue
      Gexcore::Provision::Service.app_provision_master(app.id, {}, :after_provision_master_install_app)


    end


    it 'provision master with app script' do
      # it calls app_provision_master_app_script

      # work
      res = Gexcore::ApplicationsService.install_application_by_user(@user, @app_name, @node.uid, @app_settings)

      app = ClusterApplication.get_by_id(res.data[:application_id])

      # check
      expect(Gexcore::ProvisionService).to receive(:app_provision_master_app_script).with(app.id, anything)
                                               .and_return(Gexcore::Response.res_data)


      # run from queue
      Gexcore::ProvisionService.app_provision_master(app.id, {}, :after_provision_master_install_app)


    end
=end
  end
end


