RSpec.describe "Add nodes to AWS cluster", :type => :request do
  before :each do
    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    # create cluster
    @cluster_options = build_cluster_options_aws
    @user, @cluster = create_user_and_cluster_aws(@cluster_options)

    #
    allow(@user).to receive(:can?).with(:manage, Cluster).and_return(true)

    # node data
    @sysinfo = build_node_sysinfo
    @n_nodes =1
    @instance_type = 't2.medium'
    @volume_size=100


  end





  describe "add_nodes_to_cluster_by_user" do
    before :each do

      @opts = {
          instance_type: @instance_type,
          volume_size: @volume_size,
          hadoop_app: true
      }

    end


    it "ok - response" do
      # do the work
      res = Gexcore::Nodes::Service.add_nodes_to_cluster_by_user(
          @user, @cluster.uid,
          @n_nodes, @opts)

      # check res
      expect(res.success?).to be_truthy

    end

    it "calls AWS.add_node_to_cluster" do
      #
      expect(Gexcore::Nodes::Aws::Service).to receive(:add_node_to_cluster).and_call_original

      # work
      res = Gexcore::Nodes::Service.add_nodes_to_cluster_by_user(
          @user, @cluster.uid, @n_nodes,
          @opts)

      # check res
      expect(res.success?).to be_truthy
    end

  end



  describe 'add_node_to_cluster' do

    before :each do
      #
      @opts = {
          hadoop_app: true,
          instance_type: @instance_type,
          volume_size: @volume_size,
          user_token: 'XXXaaa111'
      }

    end

    it 'ok - response' do
      # work
      res = Gexcore::Nodes::Aws::Service.add_node_to_cluster(@cluster, @opts)

      expect(res.success?).to eq true
    end


    it 'creates node in DB' do
      #
      n_nodes_old = Node.count

      # work
      res = Gexcore::Nodes::Aws::Service.add_node_to_cluster(@cluster, @opts)

      #
      n_nodes = Node.count

      expect(n_nodes).to eq n_nodes_old+1

      # check node data
      node = Node.get_by_id(res.data[:node_id])

      expect(node.uid).not_to be_nil
      expect(node.status).to eq 'installing'
      expect(node.host_type.name).to eq NodeHostType::DEDICATED
      expect(node.options_hash['aws_instance_type']).to eq @instance_type
      expect(node.options_hash['volume_size']).to eq @volume_size
    end


    it 'add async jobs' do
      # async jobs
      expect(NodeInstallAwsWorker).to receive(:perform_async)


      # work
      res = Gexcore::Nodes::Aws::Service.add_node_to_cluster(@cluster, @opts)

    end


  end

  context 'add node to cluster - with Hadoop app' do
    before :each do
      @apps = ['hadoop_cdh']
      @app_name = @apps[0]


      @opts = {
          hadoop_app: true,
          instance_type: @instance_type,
          volume_size: @volume_size,
          user_token: 'XXXaaa111'
      }

    end


    it 'create containers' do
      container_names = Gexcore::AppHadoop::App::CONTAINERS_BY_SERVICE_SLAVE.values.uniq

      # work
      res = Gexcore::Nodes::Aws::Service.add_node_to_cluster(@cluster, @opts)

      # check
      node = Node.get_by_id(res.data[:node_id])
      app = ClusterApplication.get_for_cluster(@app_name, @cluster)

      #expect(cluster.containers.count).to eq container_names.length
      expect(node.containers.count).to eq container_names.length

      container_names.each do |name|
        r = ClusterContainer.get_by_node(name, node)

        expect(r.uid).not_to be_nil
        expect(r.name).not_to be_nil
        expect(r.basename).not_to be_nil
        expect(r.hostname).to be_truthy
        expect(container_names).to include r.basename
        expect(r.status).to eq 'installing'

        expect(r.cluster_id).to eq @cluster.id
        expect(r.application_id).to eq app.id
        expect(r.node_id).to eq node.id
        expect(r.is_master).to eq false


      end
    end


    it 'services' do
      services = Gexcore::AppHadoop::App::SERVICES_SLAVE

      # work
      res = Gexcore::Nodes::Aws::Service.add_node_to_cluster(@cluster, @opts)

      # check
      node = Node.get_by_id(res.data[:node_id])
      app = ClusterApplication.get_for_cluster(@app_name, @cluster)

      # check
      services.each do |service_name, service_opts|
        r = ClusterService.get_by_name_and_node(service_name, node)

        expect(r).not_to be_nil

        #expect(r.public_ip).not_to be_nil

        expect(r.application_id).to eq app.id
        expect(r.cluster_id).to eq @cluster.id
        expect(r.node_id).to eq node.id

        expect(r.port_in).to be_truthy
        expect(r.port_out).to be_truthy

        # for AWS node - port_out should be vix proxy
        expect(r.port_out).not_to eq r.port_in

      end

    end


  end





  describe 'Provision create_node' do

    before :each do
      #
      @opts = {
          instance_type: @instance_type,
          user_token: 'XXXaaa111'
      }

      # create node
      res = Gexcore::Nodes::Aws::Service.add_node_to_cluster(@cluster, @opts)
      @node = Node.get_by_id(res.data[:node_id])
    end


    it 'after provision' do
      node = @node

      # precheck
      expect(node.status).to eq 'installing'
      expect(node.job_finished?('install')).to eq false
      expect(node.job_task_state('install', 'master')).to eq Node::JOB_STATE_STARTED


      # run provision
      Gexcore::Nodes::Provision.provision_master_create_node(@node.id)

      # check
      node.reload
      expect(node.status).to eq 'installing'
      expect(node.job_task_finished?('install', 'master')).to eq true

    end


  end




  describe 'provision create_node_aws_instance' do
    before :each do
      #
      @opts = {
          instance_type: @instance_type,
          volume_size: @volume_size
      }

      #
      res = Gexcore::Nodes::Aws::Service.add_node_to_cluster(@cluster, @opts)
      @node = Node.get_by_id(res.data[:node_id])
    end


    it 'after provision' do
      node = @node

      # precheck
      expect(node.status).to eq 'installing'
      expect(node.job_finished?('install')).to eq false
      expect(node.job_task_state('install', 'aws_instance')).to eq Node::JOB_STATE_NOTSTARTED


      # run provision
      Gexcore::Nodes::Aws::Provision.create_node_aws_instance(@node.id)

      # check
      node.reload
      expect(node.status).to eq 'installing'
      expect(node.job_task_finished?('install', 'aws_instance')).to eq true

    end


    it 'error in provision create_node_aws_instance' do
      # stub error
      stub_node_provision_error('create_node_aws_instance')
      #allow(Gexcore::ProvisionService).to receive(:run_script_ansible).with('create_node_aws_instance.yml', anything).and_call_original
      #allow_any_instance_of(Gexcore::AnsibleRequest).to receive(:run).and_return(false)


      # run provision
      Gexcore::Nodes::Aws::Provision.create_node_aws_instance(@node.id)


      # check
      @node.reload

      expect(@node.status).to eq 'uninstalling'
      expect(@node.job_finished?('install')).to eq false
      expect(@node.job_task_state('install', 'aws_instance')).to eq Node::JOB_STATE_ERROR

    end


    it 'params for provision script create_node_aws_instance' do
      raise 'TODO: finish it'
      #allow(Gexcore::Provision::Service).to receive(:run).with('create_node_aws_instance', anything).and_call_original


      # script params
      allow(Gexcore::Provision::Service).to receive(:run) do |task_name, cmd|
        expect(cmd).to match /ansible-playbook /

        puts "cmd: #{cmd}"
        #
        expect(cmd).to match(/\"_node_id\" *:#{@node.id}/i)

        expect(cmd).to match(/\"_hadoop_type\" *: *\"#{@cluster.hadoop_type.name}\"/)

        expect(cmd).to match(/\"_node_agent_token\" *: *\"#{@node.agent_token}\"/i)
        expect(cmd).to match(/\"_gex_env\" *: *\".+\"/i)

        # aws options
        expect(cmd).to match(/\"_instance_type\" *: *\"#{@instance_type}\"/)
        expect(cmd).to match(/\"_volume_size\" *: *#{@volume_size}/)


      end.and_return(Gexcore::Response.res_data)


      # run provision
      Gexcore::Nodes::Aws::Provision.create_node_aws_instance(@node)


    end

  end

end
