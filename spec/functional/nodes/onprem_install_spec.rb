RSpec.describe "Node install", :type => :request do
  before :each do
    @sysinfo = build_node_sysinfo
    @lib = Gexcore::Nodes::Service

    # stub
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    # create user with cluster
    @user, @cluster = create_user_active_and_create_cluster

    #
    @instance_id = build_instance_id
  end


  describe "create node" do
    before :each do
      allow(@user).to receive(:can?).with(:manage, Cluster).and_return(true)

      #
      @instance_id = build_instance_id

    end


    it "ok - response" do

      # do the work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo)


      # check res
      expect(res.success?).to be_truthy
      #expect(res.data[:clusterID]).not_to be_empty
      #expect(res.data[:clusterName]).not_to be_empty
      expect(res.data[:node_id]).to be_truthy
      #expect(res.data[:nodeName]).not_to be_empty

    end



    it "DB" do
      # prepare
      node_count = Node.count
      cluster_last_node_number_count = @cluster.last_node_number

      # work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo)

      #
      @cluster.reload

      #
      res_data = res.data
      node = Node.get_by_id(res_data[:node_id])

      #
      expect(Node.count).to eq(node_count+1)
      expect(@cluster.last_node_number).to eq(cluster_last_node_number_count+1)

      #
      expect(node).not_to be_nil
      #expect(node.uid).to eq(node.uid)
      #expect(node.name).to eq(res_data[:nodeName])
      expect(node.cluster_id).to eq(@cluster.id)
      #expect(node.ip).not_to be_empty
      #expect(node.port).to be > 0

      expect(node.host_type.name).to eq NodeHostType::DEFAULT_NAME

      #expect(node.system_info).to eq(@sysinfo.to_s)# ???

      expect(node.installing?).to eq true
    end

    it 'ok - status' do
      # do the work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo)

      # check
      node = Node.get_by_id(res.data[:node_id])
      expect(node.status).to eq 'installing'
      expect(node.status_changed).to be >0


    end


    it 'jobs state' do
      # do the work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo)

      # check
      node = Node.get_by_id(res.data[:node_id])

      # jobs state
      expect(node.job_finished?('install')).to eq false

      # master job - finished
      expect(node.job_task_state('install', 'master')).to eq Node::JOB_STATE_FINISHED

      # client job - not finished
      expect(node.job_task_state('install', 'client')).to eq Node::JOB_STATE_NOTSTARTED

    end



    context 'with hadoop application' do
      before :all do
        @extra_fields = {
            hadoop_app: true
        }

      end

      it 'DB node.hadoop_app_id' do
        # work
        res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, @extra_fields)

        #
        @cluster.reload

        #
        node = Node.get_by_id(res.data[:node_id])

        #
        expect(node.hadoop_app_id).to be >0
        expect(node.hadoop_app_id).to eq @cluster.hadoop_app_id
      end

      it 'containers' do
        # init
        containers_names = Gexcore::AppHadoop::App::CONTAINERS_BY_SERVICE_SLAVE.values.uniq

        # do the work
        res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, @extra_fields)

        #
        res_data = res.data

        # check
        @cluster.reload
        node = Node.get_by_id(res_data[:node_id])

        # containers
        expect(node.containers.count).to eq containers_names.length

        node.containers.each do |r|
          expect(r.uid).to be_truthy
          expect(r.basename).to be_truthy
          expect(containers_names).to include r.basename
          expect(r.name).to be_truthy
          expect(r.hostname).to be_truthy
        end


      end

      it 'calls provision provision_master_create_node'  do
        expect(Gexcore::Nodes::Provision).to receive(:provision_master_create_node)

        # do the work
        res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, @extra_fields)

      end


      it 'calls provision create_node'  do
        expect(Gexcore::Provision::Service).to receive(:run).with('create_node', anything) do |task_name, script|
          puts "cmd: #{script}"

        end

        # do the work
        res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, @extra_fields)

      end


      it 'provision create_node params' do
        expect(Gexcore::Provision::Service).to receive(:run).with('create_node', anything) do |task_name, script|
          puts "cmd: #{script}"

        end

        # do the work
        res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, @extra_fields)

      end
    end



    context 'app only node' do
      before :all do
        @extra_fields = {
            #hadoop_app: false
        }

      end

      it 'DB node.hadoop_app_id' do
        # work
        res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, @extra_fields)

        #
        @cluster.reload

        #
        node = Node.get_by_id(res.data[:node_id])

        #
        expect(node.hadoop_app_id).to be_nil

      end

      it 'no containers' do
        # do the work
        res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, @extra_fields)

        #
        res_data = res.data

        # check
        @cluster.reload
        node = Node.get_by_id(res_data[:node_id])

        # containers
        expect(node.containers.count).to eq 0

      end

      it 'calls provision' do
        expect(Gexcore::Provision::Service).to receive(:run).with('create_node', anything)

        # do the work
        res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, @extra_fields)

      end



    end


    it 'create RabbitMQ user' do
      #
      expect(Gexcore::Nodes::Control).to receive(:rabbitmq_create_user_for_node).and_return Gexcore::Response.res_data

      # do the work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo)

    end



    it 'if cannot create RabbitMQ user' do
      n_nodes = Node.count

      # ERROR while setup
      allow(Gexcore::Nodes::Control)
          .to receive(:rabbitmq_create_user_for_node)
                  .and_return Gexcore::Response.res_error("", "TEST error in RabbitMq")


      # work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo)

      # check
      expect(res.error?).to eq true
      expect(Node.count).to eq n_nodes

      node = Node.get_by_id res.data[:node_id]

      expect(node).to be_nil
      #expect(node.status).to eq 'install_error'

    end


    it 'adds Sidekiq job to fix node later' do
      #
      expect(NodesFixStatusWorker).to receive(:perform_in).with(anything, kind_of(Numeric), 'installing', 'install_error')


      # do the work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo)

    end

    it 'no permissions' do
      # prepare

      # do it
      allow(@user).to receive(:can?).with(:manage, Cluster).and_return(false)

      res = @lib.create_node_by_user(@instance_id, @user, @cluster, {})


      #execute
      expect(res.success?).to be false
      expect(res.http_status).to be 403

    end
  end


  describe 'create node with options' do
    before :each do
      allow(@user).to receive(:can?).with(:manage, Cluster).and_return(true)

      # prepare
      stub_create_node_all

      @node_options = {'selected_interface'=>{'name'=>'eth0', 'isWifi'=>false} }

    end


    it 'calls provision create_node' do
      #ansible_params = ['_proxy_ip',  '_gateway_ip', '_network_mask', '_container_ips', '_interface']
      ansible_params = ['_interface', '_is_wifi']
      containers_names = Gexcore::AppHadoop::App::CONTAINERS_BY_SERVICE_SLAVE.values.uniq

      # stub
      allow(Gexcore::Provision::Service).to receive(:run) do |task_name, cmd|
        expect(task_name).to eq 'create_node'

        puts "cmd: #{cmd}"

        # options
        args.each do |p_good|
          expect(args[p_good]).not_to be_nil
        end


      end.and_return(Gexcore::Response.res_data)

      # do the work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, {options: @node_options})


    end

  end


  describe 'after install on client' do
    before :each do
      #
      stub_create_node_all

      # prepare
      allow(@user).to receive(:can?).with(:manage, Cluster).and_return(true)

      # create node
      res = @lib.create_node(@instance_id, @cluster, @sysinfo)
      @node = Node.get_by_id(res.data[:node_id])

    end

    context 'notify node_installed' do

      it 'status starting' do
        expect(@node.installing?).to eq true

        # stub send command
        stub_node_send_command 'start'

        # installed
        Gexcore::NotificationService.notify('node_installed', {node_id: @node.id})
        #node.finish_install!

        # check
        @node.reload

        expect(@node.starting?).to eq true

      end

=begin
      it 'containers' do
        # stub send command
        stub_node_send_command 'start'

        # installed
        Gexcore::NotificationService.notify('node_installed', {node_id: @node.id})

        # check
        @node.reload

        @node.containers.all.each do |container|
          expect(container.installed?).to eq true
        end

      end
=end

      it 'send start command' do
        expect(Gexcore::Nodes::Control).to receive(:rabbitmq_add_command_to_queue).with(kind_of(Node), 'start', kind_of(Hash)).and_call_original
        #expect_any_instance_of(Bunny::Exchange).to receive(:publish).and_return(true)

        # installed
        Gexcore::NotificationService.notify('node_installed', {node_id: @node.id})

      end




      it 'if cannot send command start' do
        # notify installed from client machine

        # ERROR while sending command
        expect(Gexcore::Nodes::Control)
            .to receive(:rabbitmq_add_command_to_queue)
                    .with(kind_of(Node), 'start', kind_of(Hash))
                    .and_return(Gexcore::Response.res_error("error", "cannot send command", ""))



        # installed
        @node.finish_install!

        #
        node = Node.get_by_uid @node.uid
        node.reload

        expect(node.start_error?).to eq true


      end

      it 'if wrong node status' do
        #
        #allow(@node).to receive(:status).and_return('active')
        # stub send command
        stub_node_send_command 'start'

        # installed
        @node.finish_install!
        @node.reload

        @node.set_start_error!
        @node.reload
        expect(@node.status).to eq 'start_error'


        # do the work
        old_status = @node.status
        res = Gexcore::NotificationService.notify('node_installed', {node_id: @node.id})

        # check
        @node.reload

        expect(@node.status).to eq old_status

      end
    end
  end

end
