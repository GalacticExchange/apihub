RSpec.describe "Node lifecycle", :type => :request do

  before :each do
    @sysinfo = JSON.parse(File.read('spec/data/node_body.txt'))
    @lib = Gexcore::Nodes::Service

    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    # create user with cluster
    @user, @cluster = create_user_and_cluster_onprem

    #
    @instance_id = build_instance_id
  end


  describe 'process - install node with hadoop app' do
    before :each do
      # stub
      stub_create_node_all

      #
      @extra_fields = {
          hadoop_app: true
      }


    end

    it 'from installing to active' do
      # step1. create node
      res_create = Gexcore::Nodes::Service.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, @extra_fields)

      node_id = res_create.data[:node_id]
      node = Node.get_by_id(node_id)

      # check after create
      expect(node.installing?).to eq true

      # jobs state
      expect(node.job_finished?('install')).to eq false

      # master job - finished
      expect(node.job_task_state('install', 'master')).to eq Node::JOB_STATE_FINISHED

      # client job - not finished
      expect(node.job_task_state('install', 'client')).to eq Node::JOB_STATE_NOTSTARTED

      # check hadoop containers
      containers_names = Gexcore::AppHadoop::App::CONTAINERS_BY_SERVICE_SLAVE.values.uniq

      expect(node.containers.count).to eq containers_names.length

      node.containers.each do |container|
        expect(container.status).to eq 'installing'
      end



      # step 2. notify installed from client machine
      stub_node_send_command('start')

      Gexcore::NotificationService.notify('node_installed', {'nodeID'=> node.uid})

      # check
      node = Node.get_by_id(node_id)
      node.reload

      expect(node.starting?).to eq true

      # containers
      node.containers.each do |container|
        expect(container.status).to eq 'starting'
      end


      # step 3. agent says "node started"
      Gexcore::NotificationService.notify('node_started', {'nodeID'=> node.uid})


      #
      node = Node.get_by_id(node_id)
      node.reload

      expect(node.active?).to eq true

      # containers
      node.containers.each do |container|
        expect(container.status).to eq 'active'
      end

      ## state
      node_state = Gexcore::Nodes::Service.get_node_state(node)

      expect(node_state[:status]).to eq 'joined'

    end



  end


end
