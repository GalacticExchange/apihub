RSpec.describe "Restart container", :type => :request do

  before :each do
    @lib = Gexcore::Containers::Control

    # create user with cluster
    stub_create_user_all
    stub_create_cluster_all


    #
    @user, @cluster = create_user_and_cluster_onprem

    # master container
    @container = @cluster.get_master_container 'hadoop'

    #
    @cmd = 'restart'
  end

  describe 'Containers::Control.restart_container' do
    it 'status' do
      # work
      res = @lib.restart_container(@container)

      # check
      expect(res.success?).to eq true
      @container.reload
      expect(@container.status).to eq "restarting"
    end

    it 'adds provision in async' do
      # check
      expect(ContainerControlWorker).to receive(:perform_async)

      # work
      res = @lib.restart_container(@container)

    end

    describe 'by status' do
      describe 'for start_error container' do
        before :each do
          # prepare
          @container.set_start_error!
        end

        it 'OK' do
          # work
          res = @lib.restart_container(@container)

          # check
          expect(res.success?).to eq true
          @container.reload
          expect(@container.status).to eq "restarting"
        end

      end


      describe 'for stopped container' do
        before :each do
          # prepare
          #@container.set_stopped!
        end

        it 'stopped - OK' do
          skip 'will be later'

          # work
          res = @lib.restart_node(node)

          # check
          expect(res.success?).to eq true
          node.reload
          expect(node.status).to eq "restarting"
        end

      end

      describe 'for restart_error container' do
        before :each do
          # prepare
          @container.set_restart_error!
        end

        it 'restart_error - OK' do
          skip 'will be later'

          # prepare
          node = create_node_status_restart_error(@cluster)
          expect(node.status).to eq 'restart_error'

          # work
          res = @lib.restart_node(node)

          # check
          expect(res.success?).to eq true
          node.reload
          expect(node.status).to eq "restarting"
        end

      end
    end


  end



  describe 'provision' do
    before :each do
      # start restart
      res = @lib.restart_container(@container)

      @container.reload

      #
      stub_container_provision_all
    end

    it 'status' do
      # work
      Gexcore::Containers::Provision.run_control_command(@container.id, @cmd)

      # check
      @container.reload

      expect(@container.status).to eq 'active'

    end

    it 'provision script params' do
      # check
      expect(Gexcore::Provision::Service).to receive(:run).with('change_master_container_state_restart', anything) do |task_name, script|
        expect(task_name).to eq 'change_master_container_state_restart'

        ['_cluster_id', '_app_name', '_action'].each do |p_name|
          expect(cmd_cap_contains_param_name(script, p_name)).to eq true
        end

        Gexcore::Response.res_data
      end


      # work
      Gexcore::Containers::Provision.run_control_command(@container.id, @cmd)


    end

    it 'error in provision' do
      # error
      allow(Gexcore::Provision::Service).to receive(:run).with('change_master_container_state_restart', anything).and_return(Gexcore::Response.res_error("test_error", "test error"))

      # work
      Gexcore::Containers::Provision.run_control_command(@container.id, @cmd)

      # check
      @container.reload

      expect(@container.status).to eq 'restart_error'

    end

  end



end

