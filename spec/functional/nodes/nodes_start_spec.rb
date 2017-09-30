RSpec.describe "Start node", :type => :request do

  before :each do
    @lib = Gexcore::Nodes::Control

    # create user with cluster
    stub_create_user_all
    stub_create_cluster_all

    #
    @user, @cluster = create_user_and_cluster_onprem
  end



  describe 'Start stopped node' do
    before :each do
      stub_create_node_all

      #
      @node = create_node_status_stopped(@cluster)
    end


    it 'status' do
      # precheck
      expect(@node.status).to eq 'stopped'


      # work
      res = @lib.start_node(@node)

      # check
      @node.reload
      expect(@node.status).to eq 'starting'

    end


    it 'containers status' do
      # work
      res = @lib.start_node(@node)

      # check
      @node.reload

      @node.containers.each do |container|
        expect(container.status).to eq "starting"
      end
    end



    it 'adds Sidekiq job to fix node later' do
      # check
      expect(NodesFixStatusWorker).to receive(:perform_in).with(anything, @node.id, 'starting', 'start_error')


      # work
      res = @lib.start_node(@node)

    end


    it 'error during start' do
      # work
      # error in RabbitMQ
      allow(Gexcore::Nodes::Control).to receive(:rabbitmq_add_command_to_queue).and_return Gexcore::Response.res_error('test_error', 'error')


      res = @lib.start_node(@node)

      # check
      @node.reload
      expect(@node.status).to eq 'start_error'

    end

  end

  describe 'by status' do

    it 'active node - error' do
      #
      node = create_node_status_active(@cluster)
      expect(node.status).to eq 'active'

      # work
      res = @lib.start_node(node)

      # check
      expect(res.success?).to eq false

      node.reload
      expect(node.status).to eq 'active'


    end



    it 'stopped node - ok' do
      #
      node = create_node_status_stopped(@cluster)
      expect(node.status).to eq 'stopped'

      # work
      res = @lib.start_node(node)

      # check
      expect(res.success?).to eq true

      node.reload
      expect(node.status).to eq 'starting'

    end

    it 'restart_error - OK' do
      # prepare
      node = create_node_status_restart_error(@cluster)
      expect(node.status).to eq 'restart_error'

      # work
      res = @lib.start_node(node)

      # check
      expect(res.success?).to eq true
      node.reload
      expect(node.status).to eq "starting"
    end

    it 'install_error node - error' do
      # prepare
      node = create_node_status_install_error @cluster
      expect(node.status).to eq 'install_error'

      # work
      old_status = node.status
      res = @lib.start_node(node)

      # check
      expect(res.success?).to eq false

      node.reload
      expect(node.status).to eq old_status

    end


    it 'start_error node - ok' do
      # prepare
      node = create_node_status_start_error @cluster
      expect(node.status).to eq 'start_error'

      # work
      res = @lib.start_node(node)

      # check
      expect(res.success?).to eq true

      node.reload
      expect(node.status).to eq 'starting'

    end


    it 'stopping node - error' do
      # prepare
      node = create_node_status_stopping @cluster
      expect(node.status).to eq 'stopping'

      # work
      old_status = node.status
      res = @lib.start_node(node)

      # check
      expect(res.success?).to eq false

      node.reload
      expect(node.status).to eq old_status

    end

    it 'starting node - error' do
      # prepare
      node = create_node_status_starting @cluster
      expect(node.status).to eq 'starting'


      # work
      old_status = node.status
      res = @lib.start_node(node)

      # check
      expect(res.success?).to eq false

      node.reload
      expect(node.status).to eq old_status

    end

    it 'removed node - ignore' do
      # prepare
      node = create_node_status_removed @cluster
      expect(node.status).to eq 'removed'


      # work
      old_status = node.status
      res = @lib.start_node(node)

      # check
      expect(res.success?).to eq false

      node.reload
      expect(node.status).to eq old_status
    end

  end


  describe 'Notify NODE_STARTED' do
    before :each do
      stub_create_node_all
    end

    context 'for starting node' do
      before :each do
        # starting node
        @node = create_node_status_starting(@cluster)
      end

      it 'OK' do
        # precheck
        expect(@node.status).to eq 'starting'

        # work
        res = Gexcore::NotificationService.notify('node_started', {node_id: @node.id})

        # check
        expect(res.success?).to eq true
        @node.reload
        expect(@node.status).to eq "active"
      end

      it 'containers' do
        # work
        res = Gexcore::NotificationService.notify('node_started', {node_id: @node.id})

        # check
        @node.reload

        @node.containers.all.each do |container|
          expect(container.active?).to eq true
        end

      end

    end

    describe 'by status' do


      it 'start_error' do
        # prepare
        node = create_node_status_start_error(@cluster)
        expect(node.status).to eq 'start_error'

        # work
        res = Gexcore::NotificationService.notify('node_started', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "start_error"
      end



      it 'active' do
        # prepare
        node = create_node_status_active(@cluster)
        expect(node.status).to eq 'active'

        # work
        res = Gexcore::NotificationService.notify('node_started', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "active"
      end



      it 'install_error' do
        # prepare
        node = create_node_status_install_error(@cluster)
        expect(node.status).to eq 'install_error'

        # work
        res = Gexcore::NotificationService.notify('node_started', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "install_error"
      end

      it 'stopped' do
        # prepare
        node = create_node_status_stopped(@cluster)
        expect(node.status).to eq 'stopped'

        # work
        res = Gexcore::NotificationService.notify('node_started', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "stopped"
      end

      it 'removed node' do
        # prepare
        node = create_node_status_removed(@cluster)
        expect(node.status).to eq 'removed'

        # work
        res = Gexcore::NotificationService.notify('node_started', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        expect(res.http_status).to eq 404
        node.reload
        expect(node.status).to eq "removed"
      end

    end

  end


  describe 'Notify NODE_START_ERROR' do
    before :each do
      stub_create_node_all
    end

    context 'for starting node' do
      before :each do
        @node = create_node_status_starting(@cluster)
      end


      it 'status' do
        # precheck
        expect(@node.status).to eq 'starting'

        # work
        res = Gexcore::NotificationService.notify('node_start_error', {node_id: @node.id})

        # check
        expect(res.success?).to eq true
        @node.reload
        expect(@node.status).to eq "start_error"
      end

      it 'containers' do
        # work
        res = Gexcore::NotificationService.notify('node_start_error', {node_id: @node.id})

        # check
        @node.reload

        @node.containers do |container|
          expect(container.status).to eq "start_error"
        end

      end


    end


    describe 'by status' do

      it 'start_error' do
        # prepare
        node = create_node_status_start_error(@cluster)
        expect(node.status).to eq 'start_error'

        # work
        res = Gexcore::NotificationService.notify('node_start_error', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "start_error"
      end


      it 'active - ok' do
        # prepare
        node = create_node_status_active(@cluster)
        expect(node.status).to eq 'active'

        # work
        res = Gexcore::NotificationService.notify('node_start_error', {node_id: node.id})

        # check
        expect(res.success?).to eq true
        node.reload
        expect(node.status).to eq "start_error"
      end

      it 'install_error' do
        # prepare
        node = create_node_status_install_error(@cluster)
        expect(node.status).to eq 'install_error'

        # work
        res = Gexcore::NotificationService.notify('node_start_error', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "install_error"
      end

      it 'stopped' do
        # prepare
        node = create_node_status_stopped(@cluster)
        expect(node.status).to eq 'stopped'

        # work
        res = Gexcore::NotificationService.notify('node_start_error', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "stopped"
      end

      it 'removed node' do
        # prepare
        node = create_node_status_removed(@cluster)
        expect(node.status).to eq 'removed'

        # work
        res = Gexcore::NotificationService.notify('node_start_error', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        expect(res.http_status).to eq 404
        node.reload
        expect(node.status).to eq "removed"
      end
    end


  end
end

