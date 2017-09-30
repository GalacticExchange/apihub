RSpec.describe "Install AWS node", :type => :request do
  before :each do
    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all
    stub_node_commands_all
    stub_remove_node_all


    # create cluster
    @cluster_options = build_cluster_options_aws
    @user, @cluster = create_user_and_cluster_aws(@cluster_options)

    #
    allow(@user).to receive(:can?).with(:manage, Cluster).and_return(true)

    # node data
    @sysinfo = build_node_sysinfo
    @n_nodes =1
    @instance_type = 't2.medium'

  end

  describe 'Process' do
    before :each do
      #
      @opts = {
          instance_type: @instance_type,
          user_token: 'XXXaaa111'
      }

    end

    it 'process from installing to active' do
      # async jobs
      expect(NodeInstallAwsWorker).to receive(:perform_async)


      # work
      res = Gexcore::Nodes::Aws::Service.add_node_to_cluster(@cluster, @opts)

      # check node data
      node_id = res.data[:node_id]
      node = Node.get_by_id(res.data[:node_id])

      expect(node.status).to eq 'installing'

      # job state
      expect(node.job_finished?('install')).to eq false
      expect(node.job_task_state('install', 'master')).to be >= 0
      expect(node.job_task_state('install', 'aws_instance')).to be >= 0
      expect(node.job_task_state('install', 'client')).to be >= 0


      # run provision create_node
      Gexcore::Nodes::Provision.provision_master_create_node(node.id)


      # check
      #node = Node.get_by_id(node_id)
      node.reload
      expect(node.status).to eq 'installing'
      expect(node.job_task_finished?('install', 'master')).to eq true


      # run provision aws_instance
      Gexcore::Nodes::Aws::Provision.create_node_aws_instance(node)


      #
      #node = Node.get_by_id(res.data[:node_id])
      node.reload
      expect(node.status).to eq 'installing'
      expect(node.job_task_finished?('install', 'aws_instance')).to eq true


      # aws instance is created

      # gexd start node install
      Gexcore::NotificationService.notify('node_client_installing', {'nodeID'=> node.uid})

      # gexd installs node

      # gexd notify installed
      Gexcore::NotificationService.notify('node_client_installed', {'nodeID'=> node.uid})

      #
      node.reload
      expect(node.job_task_finished?('install', 'client')).to eq true

      # install job finished
      expect(node.job_finished?('install')).to eq true


      # all install jobs finished
      expect(node.status).to eq 'starting'


      # gexd starts node

      # gexd notify started
      Gexcore::NotificationService.notify('node_started', {'nodeID'=> node.uid})

      #
      node.reload
      expect(node.status).to eq 'active'


      ## state
      node_state = Gexcore::Nodes::Service.get_node_state(node)

      expect(node_state[:status]).to eq 'joined'

    end



    it 'if error in provision create_node' do
      # error in provision
      stub_node_provision_error('create_node')

      # work
      res = Gexcore::Nodes::Aws::Service.add_node_to_cluster(@cluster, @opts)

      # check node data
      node = Node.get_by_id(res.data[:node_id])

      expect(node.status).to eq 'installing'
      expect(node.job_finished?('install')).to eq false


      # run provision create_node.yml - error here
      Gexcore::Nodes::Provision.provision_master_create_node(node.id)


      # check
      node.reload
      expect(node.status).to eq 'uninstalling'
      expect(node.job_finished?('install')).to eq false
      expect(node.job_task_state('install', 'master')).to eq Node::JOB_STATE_ERROR


      # run provision aws_instance.yml - OK
      Gexcore::Nodes::Aws::Provision.create_node_aws_instance(node)


      # check
      node.reload
      expect(node.status).to eq 'uninstalling'
      expect(node.job_finished?('install')).to eq false
      expect(node.job_task_state('install', 'aws_instance')).to eq Node::JOB_STATE_FINISHED



    end



    it 'if error in provision create_node_aws_instance' do
      # error in provision
      stub_node_provision_error('create_node_aws_instance')

      # work
      res = Gexcore::Nodes::Aws::Service.add_node_to_cluster(@cluster, @opts)

      # check node data
      node = Node.get_by_id(res.data[:node_id])

      expect(node.status).to eq 'installing'
      expect(node.job_finished?('install')).to eq false


      # run provision create_node.yml - OK
      Gexcore::Nodes::Provision.provision_master_create_node(node.id)


      # check
      node.reload
      expect(node.status).to eq 'installing'
      expect(node.job_finished?('install')).to eq false
      expect(node.job_task_state('install', 'master')).to eq Node::JOB_STATE_FINISHED


      # run provision aws_instance.yml - error here
      Gexcore::Nodes::Aws::Provision.create_node_aws_instance(node)


      # check
      node.reload
      expect(node.status).to eq 'uninstalling'
      expect(node.job_finished?('install')).to eq false
      expect(node.job_task_state('install', 'aws_instance')).to eq Node::JOB_STATE_ERROR


    end


    it 'if error on client - gexd notifies install_error' do
      # work
      res = Gexcore::Nodes::Aws::Service.add_node_to_cluster(@cluster, @opts)

      # check node data
      node = Node.get_by_id(res.data[:node_id])

      # run provision create_node.yml - OK
      Gexcore::Nodes::Provision.provision_master_create_node(node.id)

      node.reload

      # run provision aws_instance.yml - OK
      Gexcore::Nodes::Aws::Provision.create_node_aws_instance(node)

      # check after two provisions
      node.reload
      expect(node.status).to eq 'installing'
      expect(node.job_finished?('install')).to eq false
      expect(node.job_task_finished?('install', 'master')).to eq true
      expect(node.job_task_finished?('install', 'aws_instance')).to eq true


      # gexd installs node



      # gexd notifies node_client_install_error
      Gexcore::NotificationService.notify('node_client_install_error', {'nodeID' => node.uid})

      #
      node.reload
      expect(node.status).to eq 'uninstalling'
      expect(node.job_finished?('install')).to eq false
      expect(node.job_task_state('install', 'client')).to eq Node::JOB_STATE_ERROR


      # run provision to uninstall
      Gexcore::Nodes::Aws::Provision.uninstall_node(node.id)

      #
      node.reload
      expect(node.status).to eq 'removed'

    end

  end

end


