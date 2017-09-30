RSpec.describe "Uninstall AWS node", :type => :request do

  before :each do
    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all
    stub_remove_node_all

    # create user with cluster
    @user, @cluster = create_user_and_cluster_aws

    #
    @instance_id = build_instance_id
  end


  describe 'uninstall active node' do

    before :each do
      # have active node
      @node = create_node_active @cluster
    end


    it 'uninstalling' do
      # work
      Gexcore::Nodes::Service.uninstall_node(@node)

      # check
      @node.reload
      expect(@node.status).to eq 'uninstalling'

    end

    it 'adds provision in async' do
      # check
      expect(NodeUninstallAwsWorker).to receive(:perform_async)

      # work
      Gexcore::Nodes::Service.uninstall_node(@node)

      #Gexcore::Nodes::Aws::Provision
    end

    it 'jobs state for uninstall process' do
      # work
      Gexcore::Nodes::Service.uninstall_node(@node)

      # check
      @node.reload
      expect(@node.job_finished?('uninstall')).to eq false
      expect(@node.job_task_not_finished?('uninstall', 'master')).to eq true
    end


    describe 'provision' do
      before :each do
        # start uninstall
        Gexcore::Nodes::Service.uninstall_node(@node)
      end

      it 'remove after provision finishes' do
        # run provision
        Gexcore::Nodes::Aws::Provision.uninstall_node(@node.id)

        # check
        @node.reload
        expect(@node.removed?).to eq true

      end

      it 'run remove' do
        expect(Gexcore::Nodes::Service).to receive(:remove_node)

        # run provision
        Gexcore::Nodes::Aws::Provision.uninstall_node(@node.id)

      end

      it 'calls provision remove_node' do
        # check
        expect(Gexcore::Provision::Service).to receive(:run).with('remove_node', anything).and_return(Gexcore::Response.res_data)


        # run provision
        Gexcore::Nodes::Aws::Provision.uninstall_node(@node.id)

      end

      it 'if error in provision' do
        # error in provision
        allow(Gexcore::Provision::Service).to receive(:run)
                                                .with('remove_node', anything)
                                                .and_return(Gexcore::Response.res_error('test_error', 'test error'))

        # run provision
        Gexcore::Nodes::Aws::Provision.uninstall_node(@node.id)



        # check
        @node.reload
        expect(@node.status).to eq 'uninstall_error'

      end
    end

  end

  describe 'uninstall uninstall_error node' do

  end

  describe 'uninstall install_error node' do

  end

  describe 'uninstall removed node' do

    it 'uninstall removed node' do
      node = create_node @cluster

      # remove node
      stub_node_remove_rabbitmq
      Gexcore::Nodes::Service.remove_node node
      node.reload

      #
      expect(node.removed?).to eq true

      # uninstall process
      stub_node_remove_rabbitmq
      Gexcore::NotificationService.notify('node_uninstalling', {node_id: node.id})
      node.reload

      expect(node.removed?).to eq true

      #
      Gexcore::NotificationService.notify('node_uninstalled', {node_id: node.id})
      node.reload

      expect(node.removed?).to eq true
    end

  end

  describe 'uninstall uninstall_error node' do

  end
end
