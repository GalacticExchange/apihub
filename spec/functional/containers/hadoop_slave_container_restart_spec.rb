RSpec.describe "Restart Hadoop slave container", :type => :request do

  before :each do
    @lib = Gexcore::Containers::Control

    # create user with cluster
    stub_create_user_all
    stub_create_cluster_all


    #
    @user, @cluster = create_user_and_cluster_onprem

    #
    stub_container_provision_all

    # active node
    stub_create_node_all

    @node = create_node_active(@cluster)

    # container
    @container = Gexcore::Containers::Service.get_slave_by_basename(@node, 'hadoop')


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

    it 'send command to node' do
      # check
      expect(Gexcore::Nodes::Control).to receive(:rabbitmq_add_command_to_queue) do |node, action, p|
        expect(node.id).to eq @container.node_id
        expect(action).to eq 'restartContainer'

        expect(p[:containerID]).not_to be_nil

      end

      # work
      res = @lib.restart_container(@container)
    end

  end






  describe 'Notify CONTAINER_RESTARTED' do

    describe 'for restarting container' do
      before :each do
        # restart
        res = @lib.restart_container(@container)

        @container.reload


      end


      it 'status' do
        # precheck
        expect(@container.status).to eq 'restarting'


        # work
        Gexcore::Containers::Notification.notify_restarted(@container)


        # check
        @container.reload

        expect(@container.status).to eq 'active'

      end
    end



    describe 'for stopped container' do

      before :each do
        # stop container
        Gexcore::Containers::Control.stop_container(@container)
        Gexcore::Containers::Notification.notify_stopped(@container)

        @container.reload


      end


      it 'current status stopped - not change' do
        # precheck
        expect(@container.status).to eq 'stopped'

        # work
        res = Gexcore::Containers::Notification.notify_restarted(@container)

        # check
        expect(res.success?).to eq false
        @container.reload
        expect(@container.status).to eq "stopped"
      end

    end


    describe 'for removed container' do

      it 'not change' do
        skip 'will be later'


      end

    end

  end


  describe 'Notify CONTAINER_RESTART_ERROR' do
    before :each do
      # start restart
      Gexcore::Containers::Control.restart_container @container
    end

    describe 'OK' do
      it 'status' do
        # work
        res = Gexcore::Containers::Notification.notify_restart_error(@container)

        # check
        expect(res.success?).to eq true
        @container.reload
        expect(@container.status).to eq "restart_error"
      end
    end
  end

end

