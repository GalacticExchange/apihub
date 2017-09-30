RSpec.describe "Start AWS node", :type => :request do

  before :each do
    # create user with cluster
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all
    stub_node_commands_all

    # create
    @user, @cluster = create_user_and_cluster_aws


  end



  describe 'Start stopped node' do
    before :each do

      #
      @node = create_node_active(@cluster)

      # stop node
      Gexcore::Nodes::Control.stop_node(@node)

      #
      @cmd = 'start'
    end


    it 'OK process' do
      # work
      res = Gexcore::Nodes::Control.start_node(@node)

      #
      @node.reload

      expect(@node.status).to eq 'starting'
    end


    it 'adds Sidekiq job to fix node later' do
      # stopped node
      #node = create_node_status_stopped(@cluster)
      #expect(node.status).to eq 'stopped'

      #
      expect(NodesFixStatusWorker).to receive(:perform_in).with(anything, @node.id, 'starting', 'start_error')


      # work
      res = Gexcore::Nodes::Control.start_node(@node)

    end


    it 'send command to rabbitmq' do
      # RabbitMQ
      expect(Gexcore::Nodes::Control).to receive(:send_command_to_node)
        .with(kind_of(Node), 'start')
        .and_return(Gexcore::Response.res_data)

      # work
      res = Gexcore::Nodes::Control.start_node(@node)


    end


    it 'calls provision' do
      #
      #allow(Gexcore::Nodes::Aws::Provision).to receive(:start_node).and_call_original


      # script params
      allow(Gexcore::Provision::Service).to receive(:run) do |task_name, script|
        puts "cmd: #{script}"

        expect(script).to match /provision:change_aws_node_state/
        expect(script).to match(/_cluster_id=#{@node.cluster_id}/i)
        expect(script).to match(/_node_id=#{@node.id}/i)
        #expect(script).to match(/_node_uid=#{@node.uid}/i)
        expect(script).to match(/_action=#{@cmd}/i)

      end.and_return(Gexcore::Response.res_data)


      # work
      Gexcore::Nodes::Control.start_node(@node)

    end

    it 'if error in provision' do
      # error
      allow(Gexcore::Provision::Service).to(
          receive(:run)
          .with('change_aws_node_state_start', anything)
          .and_return(Gexcore::Response.res_error('test_error', 'test error'))
      )



      # work
      Gexcore::Nodes::Control.start_node(@node)

      # check
      @node.reload

      expect(@node.status).to eq 'start_error'
    end

  end


end

