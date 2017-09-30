RSpec.describe "Restart node", :type => :request do

  before :each do
    @lib = Gexcore::Nodes::Control

    # create user with cluster
    stub_create_user_all
    stub_create_cluster_all

    #
    @user, @cluster = create_user_and_cluster_onprem
  end

  describe 'Begin restart node' do
    before :each do
      stub_create_node_all
    end

    describe 'restart active node' do
      before :each do
        @node = create_node_status_active(@cluster)
      end

      it 'status' do
        # prepare
        expect(@node.status).to eq 'active'

        # work
        res = @lib.restart_node(@node)

        # check
        expect(res.success?).to eq true
        @node.reload
        expect(@node.status).to eq "restarting"
      end

      it 'containers status' do
        # work
        res = @lib.restart_node(@node)

        # check
        @node.reload

        @node.containers.each do |container|
          expect(container.status).to eq "restarting"
        end

      end
    end


    describe 'by status' do

      it 'start_error - OK' do
        # prepare
        node = create_node_status_start_error(@cluster)
        expect(node.status).to eq 'start_error'

        # work
        res = @lib.restart_node(node)

        # check
        expect(res.success?).to eq true
        node.reload
        expect(node.status).to eq "restarting"
      end



      it 'stopped - OK' do
        # prepare
        node = create_node_status_stopped(@cluster)
        expect(node.status).to eq 'stopped'

        # work
        res = @lib.restart_node(node)

        # check
        expect(res.success?).to eq true
        node.reload
        expect(node.status).to eq "restarting"
      end

      it 'stop_error - OK' do
        # prepare
        node = create_node_status_stop_error(@cluster)
        expect(node.status).to eq 'stop_error'

        # work
        res = @lib.restart_node(node)

        # check
        expect(res.success?).to eq true
        node.reload
        expect(node.status).to eq "restarting"
      end

      it 'restart_error - OK' do
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


      it 'starting - BAD' do
        # prepare
        node = create_node_status_starting(@cluster)
        expect(node.status).to eq 'starting'

        # work
        res = @lib.restart_node(node)

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "starting"
      end


      it 'install_error - BAD' do
        # prepare
        node = create_node_status_install_error(@cluster)
        expect(node.status).to eq 'install_error'

        # work
        res = @lib.restart_node(node)

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "install_error"
      end


      it 'removed node' do
        # prepare
        node = create_node_status_removed(@cluster)
        expect(node.status).to eq 'removed'

        # work
        res = @lib.restart_node(node)

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "removed"
      end

    end

  end


  describe 'Notify NODE_RESTARTED' do
    before :each do
      stub_create_node_all
    end

    describe 'for restarting node' do
      before :each do
        @node = create_node_status_restarting(@cluster)
      end

      it 'status' do
        # precheck
        expect(@node.status).to eq 'restarting'

        # work
        res = Gexcore::NotificationService.notify('node_restarted', {node_id: @node.id})

        # check
        expect(res.success?).to eq true
        @node.reload
        expect(@node.status).to eq "active"
      end

      it 'containers' do
        # work
        res = Gexcore::NotificationService.notify('node_restarted', {node_id: @node.id})

        # check
        @node.reload

        @node.containers.each do |container|
          expect(container.status).to eq "active"
        end

      end

    end

    describe 'by node status' do

      it 'active - OK' do
        # prepare
        node = create_node_status_active(@cluster)
        expect(node.status).to eq 'active'

        # work
        res = Gexcore::NotificationService.notify('node_restarted', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "active"
      end

      it 'stopped - OK' do
        # prepare
        node = create_node_status_stopped(@cluster)
        expect(node.status).to eq 'stopped'

        # work
        res = Gexcore::NotificationService.notify('node_restarted', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "stopped"
      end

      it 'stop_error - OK' do
        # prepare
        node = create_node_status_stop_error(@cluster)
        expect(node.status).to eq 'stop_error'

        # work
        res = Gexcore::NotificationService.notify('node_restarted', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "stop_error"
      end

      it 'starting - BAD' do
        # prepare
        node = create_node_status_starting(@cluster)
        expect(node.status).to eq 'starting'

        # work
        res = Gexcore::NotificationService.notify('node_restarted', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "starting"
      end


      it 'install_error - BAD' do
        # prepare
        node = create_node_status_install_error(@cluster)
        expect(node.status).to eq 'install_error'

        # work
        res = Gexcore::NotificationService.notify('node_restarted', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "install_error"
      end


      it 'removed node' do
        # prepare
        node = create_node_status_removed(@cluster)
        expect(node.status).to eq 'removed'

        # work
        res = Gexcore::NotificationService.notify('node_restarted', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        expect(res.http_status).to eq 404
        node.reload
        expect(node.status).to eq "removed"
      end

    end

  end



  describe 'Notify NODE_RESTART_ERROR' do
    before :each do
      stub_create_node_all
    end


    context 'for restarting node' do
      before :each do
        @node = create_node_status_restarting(@cluster)
      end

      it 'status' do
        # precheck
        expect(@node.status).to eq 'restarting'

        # work
        res = Gexcore::NotificationService.notify('node_restart_error', {node_id: @node.id})

        # check
        expect(res.success?).to eq true
        @node.reload
        expect(@node.status).to eq "restart_error"
      end


      it 'containers' do
        # work
        res = Gexcore::NotificationService.notify('node_restart_error', {node_id: @node.id})

        # check
        @node.reload

        @node.containers do |container|
          expect(container.status).to eq "restart_error"
        end

      end

    end

    describe 'by status' do

      it 'active - OK' do
        # prepare
        node = create_node_status_active(@cluster)
        expect(node.status).to eq 'active'

        # work
        res = Gexcore::NotificationService.notify('node_restart_error', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "active"
      end

      it 'stopped - OK' do
        # prepare
        node = create_node_status_stopped(@cluster)
        expect(node.status).to eq 'stopped'

        # work
        res = Gexcore::NotificationService.notify('node_restart_error', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "stopped"
      end

      it 'stop_error - OK' do
        # prepare
        node = create_node_status_stop_error(@cluster)
        expect(node.status).to eq 'stop_error'

        # work
        res = Gexcore::NotificationService.notify('node_restart_error', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "stop_error"
      end

      it 'starting - BAD' do
        # prepare
        node = create_node_status_starting(@cluster)
        expect(node.status).to eq 'starting'

        # work
        res = Gexcore::NotificationService.notify('node_restart_error', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "starting"
      end


      it 'install_error - BAD' do
        # prepare
        node = create_node_status_install_error(@cluster)
        expect(node.status).to eq 'install_error'

        # work
        res = Gexcore::NotificationService.notify('node_restart_error', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        node.reload
        expect(node.status).to eq "install_error"
      end


      it 'removed node' do
        # prepare
        node = create_node_status_removed(@cluster)
        expect(node.status).to eq 'removed'

        # work
        res = Gexcore::NotificationService.notify('node_restart_error', {node_id: node.id})

        # check
        expect(res.success?).to eq false
        expect(res.http_status).to eq 404
        node.reload
        expect(node.status).to eq "removed"
      end

    end

  end

end

