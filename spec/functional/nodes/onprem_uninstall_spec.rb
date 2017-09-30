RSpec.describe "Node uninstall", :type => :request do

  before :each do
    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    # create user with cluster
    @user, @cluster = create_user_and_cluster_onprem

    # stub permissions
    allow(@user).to receive(:can?).with(:manage, Cluster).and_return(true)

  end


  describe "notify node_uninstalling" do
    before :each do



    end

    context 'active node with hadoop app' do

      before :each do
        # active node with hadoop
        @node = create_node_hadoop_active(@cluster)

      end

      it 'status' do
        # work
        Gexcore::NotificationService.notify('node_uninstalling', {node_id: @node.id})

        # check
        @node.reload

        expect(@node.uninstalling?).to eq true

      end

      it 'calls uninstall' do
        expect(Gexcore::Nodes::Service).to receive(:uninstall_node).with(@node)

        # work
        Gexcore::NotificationService.notify('node_uninstalling', {node_id: @node.id})

      end

      it 'containers' do
        # work
        Gexcore::NotificationService.notify('node_uninstalling', {node_id: @node.id})

        # check
        @node.reload

        expect(@node.containers.count).to be > 0

        @node.containers.each do |container|
          expect(container.status).to eq 'uninstalling'
        end

      end

      it 'adds Sidekiq job to fix node later' do
        #
        expect(NodesFixStatusWorker).to receive(:perform_in).with(anything, @node.id, 'uninstalling', 'uninstall_error')


        # do the work
        Gexcore::NotificationService.notify('node_uninstalling', {node_id: @node.id})

      end


      it 'calls provision master' do
        # expect
        #expect(Gexcore::ProvisionService).to receive(:run_script_ansible).with('remove_node.yml', anything)
        expect(NodeUninstallProvisionMasterWorker).to receive(:perform_async).with(@node.id, anything).and_return true

        # work
        Gexcore::NotificationService.notify('node_uninstalling', {node_id: @node.id})

      end


    end

    describe 'by status' do
      it "for starting node" do
        #
        @node = create_node_status_installed(@cluster)

        # pre check
        expect(@node.starting?).to eq true

        # do the work
        Gexcore::NotificationService.notify('node_uninstalling', {node_id: @node.id})

        # check
        @node.reload

        expect(@node.uninstalling?).to eq true

      end

      it 'for removed node' do
        node = create_node_active(@cluster)

        # remove node
        stub_node_remove_rabbitmq
        Gexcore::Nodes::Service.remove_node node

        node.reload

        # pre check
        expect(node.removed?).to eq true

        # do the work
        res = Gexcore::NotificationService.notify('node_uninstalling', {node_id: node.id})

        # check
        node.reload

        expect(res.http_status).to eq 404

        expect(node.removed?).to eq true

      end
    end
  end


  describe 'provision remove_node' do
    before :each do
      # active node
      @node = create_node_active(@cluster)

    end

    it 'params for provision script remove_node' do
      good_params = [
          '_cluster_id',
          '_node_id'
      ]

      # stub
      allow(Gexcore::Provision::Service).to receive(:run) do |task_name, cmd|
        expect(task_name).to eq 'remove_node'

        puts "cmd: #{cmd}"

        # options
        #good_params.each do |p_good|
        #expect(args[p_good]).not_to be_nil
        #expect(cmd_contains_param_name(cmd, p_good)).to eq true
        #end

        expect(cmd).to match /_cluster_id=/
        expect(cmd).to match /node_id=/


      end.and_return(Gexcore::Response.res_data)

      # work
      Gexcore::NotificationService.notify('node_uninstalling', {node_id: @node.id})


      # run from queue
      Gexcore::Nodes::Provision.provision_master_uninstall_node(@node.id, {})


    end

  end


  describe 'notify uninstalled' do
    before :each do


    end


    describe 'notify uninstalled for uninstalling node' do
      it 'status' do
        # active node
        node = create_node_active @cluster

        # start uninstall
        Gexcore::NotificationService.notify('node_uninstalling', {node_id: node.id})
        node.reload

        # do the work
        # stub rabbitmq operations
        stub_node_remove_rabbitmq

        #
        Gexcore::NotificationService.notify('node_uninstalled', {node_id: node.id})

        # check
        node.reload
        expect(node.status).to eq 'uninstalling'

      end
    end



    describe 'by status' do
      it 'wrong node state - active' do
        #
        node = create_node_active(@cluster)

        # pre check
        expect(node.active?).to eq true

        # do the work

        # stub rabbitmq operations
        stub_node_remove_rabbitmq

        #
        Gexcore::NotificationService.notify('node_uninstalled', {node_id: node.id})

        # check - state not changed
        node.reload
        expect(node.active?).to eq true

      end

      it 'wrong node state - uninstall_error' do
        #
        node = create_node(@cluster)

        node.set_install_error!
        node.reload

        # pre check
        expect(node.install_error?).to eq true

        # do the work

        # stub rabbitmq operations
        stub_node_remove_rabbitmq

        #
        Gexcore::NotificationService.notify('node_uninstalled', {node_id: node.id})

        # check - state not changed
        node.reload
        expect(node.install_error?).to eq true
      end

      it 'removed node' do
        # active node
        node = create_node_active(@cluster)

        # remove node
        stub_node_remove_rabbitmq
        Gexcore::Nodes::Service.remove_node node

        # pre check
        node.reload
        expect(node.removed?).to eq true


        # do the work
        res = Gexcore::NotificationService.notify('node_uninstalled', {node_id: node.id})

        # check
        node.reload

        expect(res.http_status).to eq 404

        expect(node.removed?).to eq true

      end
    end

  end


  describe 'notify uninstall_error' do
    it 'ok - for uninstalling node' do
      #
      node = create_node_active(@cluster)
      Gexcore::NotificationService.notify('node_uninstalling', {node_id: node.id})
      node.reload
      expect(node.uninstalling?).to eq true

      # work
      Gexcore::NotificationService.notify('node_uninstall_error', {node_id: node.id})

      # check
      node.reload
      expect(node.uninstall_error?).to eq true

    end

    it 'wrong node state' do
      #
      node = create_node_active(@cluster)
      expect(node.active?).to eq true

      # work
      Gexcore::NotificationService.notify('node_uninstall_error', {node_id: node.id})

      # check - state not changed
      node.reload
      expect(node.active?).to eq true

    end
  end

end
