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


  describe 'Process' do
    it 'OK' do

      # it should send command to node
      expect(Gexcore::Nodes::Control).to receive(:rabbitmq_add_command_to_queue).with(kind_of(Node), 'restartContainer', kind_of(Hash))

      # work
      res = @lib.restart_container(@container)

      #
      expect(res.success?).to eq true

      # status
      @container.reload
      expect(@container.status).to eq 'restarting'


      # gexd performs the command and notify
      Gexcore::Containers::Notification.notify('restarted', {'containerID'=>@container.uid})
      #Gexcore::Containers::Notification.notify_restarted(@container)

      # check
      @container.reload
      expect(@container.status).to eq 'active'


    end

    it 'process - error in provision' do
      # work
      res = @lib.restart_container(@container)

      # status
      @container.reload
      expect(@container.status).to eq 'restarting'

      # gexd performs the command and notify about error
      Gexcore::Containers::Notification.notify_restart_error(@container)

      # check
      @container.reload
      expect(@container.status).to eq 'restart_error'

    end
  end


end

