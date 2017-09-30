RSpec.describe "Create application in AWS cluster", :type => :request do
  before :each do
    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    # create user with cluster
    @user, @cluster = create_user_and_cluster_aws

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


    # stub
    stub_create_app_all
  end


  describe "create application" do
    before :each do

    end


    it 'DB' do
      # before
      @n_applications_old = ClusterApplication.count
      @n_containers_old = ClusterContainer.count


      # work
      res = Gexcore::Applications::Service.install_application_by_user(@user, @app_name, @node.uid, @app_settings)

      # check
      expect(res.success?).to eq true

      expect(ClusterApplication.count).to eq @n_applications_old+1
      expect(ClusterContainer.count).to eq @n_containers_old+1

      # app
      app = ClusterApplication.get_by_id(res.data[:application_id])


      expect(app.name).to eq @app_name
      expect(app.uid).to be_truthy
      expect(app.library_application_id).to eq @app_library.id
      expect(app.cluster_id).to eq @cluster.id
      expect(app.status).to eq 'installing'

      settings = app.settings
      expect(settings).to be_truthy

      # containers

      #container = ClusterContainer.get_by_id(res.data[:container_id])

      app.containers.each do |container|

        expect(container.uid).to be_truthy
        expect(container.basename).to eq @app_name
        expect(container.name).to eq "#{@app_name}-#{@node.name}"
        expect(container.hostname).to eq "#{@app_name}-#{@node.name}.gex"

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



    end

    it 'services' do
      # work
      res = Gexcore::Applications::Service.install_application_by_user(@user, @app_name, @node.uid, @app_settings)


      # check
      app = ClusterApplication.get_by_id(res.data[:application_id])

      # check
      #@services.each do |service_name, service_opts|
      app.services.each do |r|
        #expect(r.public_ip).not_to be_nil

        #expect(r.application_id).to eq app.id
        expect(r.cluster_id).to eq @cluster.id
        #expect(r.node_id).to eq node.id

        expect(r.port_in).to be_truthy
        expect(r.port_out).to be_truthy

        # for AWS node - port_out should be via proxy
        if r.protocol=='ssh' || r.protocol=='http'
          expect(r.port_out).not_to eq r.port_in
        end


      end

    end

    it 'generate config.json' do
      # work
      #res = Gexcore::Applications::Service.install_application(nil, @app_name, @node, @app_settings)
      res = Gexcore::Applications::Service.install_application_by_user(@user, @app_name, @node.uid, @app_settings)

      # check
      expect(res.success?).to eq true

      #container = ClusterContainer.get_by_id(res.data[:container_id])
      app = ClusterApplication.get_by_id(res.data[:application_id])

      filename = Gexcore::Applications::Service.config_for_application_filename(app)

      text = File.read(filename)
      config_data = JSON.parse(text)

      expect(config_data['base'].is_a?(Hash)).to eq true
      #expect(config_data['base']['application_name']).to eq app.name

    end

    describe 'provision master' do

      it 'calls provision master async' do
        #
        expect(AppProvisionMasterWorker).to receive(:perform_async).and_return true

        # work
        res = Gexcore::Applications::Service.install_application_by_user(@user, @app_name, @node.uid, @app_settings)

      end

      it 'calls provision script add_app' do

        # work
        res = Gexcore::Applications::Service.install_application_by_user(@user, @app_name, @node.uid, @app_settings)

        app = ClusterApplication.get_by_id(res.data[:application_id])

        # check
        expect(Gexcore::Provision::Service).to receive(:run).with('add_app', anything)

        # run from queue
        Gexcore::Applications::Provision.app_provision_master(app.id, {}, :after_provision_master_install_app)


      end

      it 'params for add_app' do
        # work
        res = Gexcore::Applications::Service.install_application_by_user(@user, @app_name, @node.uid, @app_settings)

        # check
        app = ClusterApplication.get_by_id(res.data[:application_id])


        #expect(Gexcore::Provision::Service).to receive(:run).with('app_install_master', anything) do |task_name, cmd|
        expect(Gexcore::Provision::Service).to receive(:run) do |task_name, cmd|
          expect(task_name).to eq 'add_app'

          expect(cmd).to match(/\"_ssh_services\":/)
          expect(cmd).to match(/\"_web_services\":/)

          # services
          #enterprise_ansible_params.each do |p_good|
          #  expect(cmd).to match(/ #{p_good} *=/)
          #end

        end.and_return(Gexcore::Response.res_data)


        #allow(Gexcore::Provision::Service).to receive(:run).with('app_install_master', anything).and_return(Gexcore::Response.res_data)
        allow(Gexcore::Provision::Service).to receive(:run).with('app_install_master', anything).and_return(Gexcore::Response.res_data)
        #allow(Gexcore::Provision::Service).to receive(:run).and_return(Gexcore::Response.res_data)



        # run from queue
        Gexcore::Applications::Provision.app_provision_master(app.id, {}, :after_provision_master_install_app)

      end

      it 'provision master with app script' do
        # it calls app_provision_master_app_script

        # work
        res = Gexcore::Applications::Service.install_application_by_user(@user, @app_name, @node.uid, @app_settings)

        app = ClusterApplication.get_by_id(res.data[:application_id])

        # check
        expect(Gexcore::Applications::Provision).to receive(:app_provision_master_app_script).with(app.id, anything)
                                                 .and_return(Gexcore::Response.res_data)


        # run from queue
        Gexcore::Applications::Provision.app_provision_master(app.id, {}, :after_provision_master_install_app)


      end

    end




  end
end


