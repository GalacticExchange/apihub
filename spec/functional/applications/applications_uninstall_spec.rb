RSpec.describe "Uninstall application", :type => :request do

  before :each do
    stub_create_node_all

    # app
    @app, @node, @cluster, @user = create_app_active


  end

  describe 'uninstall app' do
    before :each do
      #
      stub_app_uninstall

    end

    it 'DB' do
      # pre check
      expect(@app.status).to eq 'active'

      # work
      res = Gexcore::Applications::Service.uninstall_application(nil, @app)


      # check
      expect(res.success?).to eq true

      app = @app
      app.reload
      expect(app.status).to eq 'uninstalling'

      # container
      app.containers.each do |container|
        expect(container.status).to eq 'uninstalling'
      end
    end



    it 'provision master with app script async' do
      #
      expect(AppUninstallProvisionMasterWorker).to receive(:perform_async).and_return true

      # work
      res = Gexcore::Applications::Service.uninstall_application(nil, @app)

    end


    it 'calls provision master with remove_app' do
      # check
      expect(Gexcore::Provision::Service).to receive(:run).with('remove_app', anything).and_return(Gexcore::Response.res_data)

      # work
      res = Gexcore::Applications::Service.uninstall_application(nil, @app)

      # run from queue
      Gexcore::Applications::Provision.app_uninstall_provision_master(@app.id, {}, :after_provision_master_uninstall_app)

    end

    it 'provision master - params' do
      #
      good_params = [
          '_cluster_id',
          '_cluster_uid',
          '_cluster_name',
      ]

      # stub
      allow(Gexcore::Provision::Service).to receive(:run) do |task_name, cmd|
        expect(task_name).to eq 'app_uninstall_master_app'

        puts "cmd: #{cmd}"

        # chef

        # options
        good_params.each do |p_good|
          #expect(args[p_good]).not_to be_nil
        end
      end.and_return(Gexcore::Response.res_data)


      # work
      res = Gexcore::Applications::Service.uninstall_application(nil, @app)

      # run from queue
      Gexcore::Applications::Provision.app_uninstall_provision_master(@app.id, {}, :after_provision_master_uninstall_app)

    end



    it 'calls provision master with app script' do
      # check
      expect(Gexcore::Applications::Provision).to receive(:app_uninstall_provision_master_app_script).with(@app.id, anything)

      # work
      res = Gexcore::Applications::Service.uninstall_application(nil, @app)

      # run from queue
      Gexcore::Applications::Provision.app_uninstall_provision_master(@app.id, {}, :after_provision_master_uninstall_app)

    end




    it 'send command to gexd' do
      # check
      expect(Gexcore::Nodes::Control).to receive(:rabbitmq_add_command_to_queue).with(@node, 'uninstallApplication', kind_of(Hash)).and_return(Gexcore::Response.res_data)

      # work
      res = Gexcore::Applications::Service.uninstall_application(nil, @app)

    end


  end

  describe 'uninstall removed app' do
    before :each do
      #
      stub_app_uninstall

      #
      res = Gexcore::Applications::Service.remove_application(@app)

      @app.reload

    end

    it 'DB' do
      # precheck
      expect(@app.status).to eq 'removed'

      # work
      res = Gexcore::Applications::Service.uninstall_application_by_user(@user, @app.uid)


      # check
      #expect(res.success?).to eq true
      expect(res.http_status).to eq 404

      app = @app
      app.reload
      expect(app.status).to eq 'removed'

      # container
      app.containers.each do |container|
        expect(container.status).to eq 'removed'
      end
    end
  end

end
