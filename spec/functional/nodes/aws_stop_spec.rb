RSpec.describe "Stop AWS node", :type => :request do

  before :each do
    # create user with cluster
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all
    stub_node_commands_all

    # create
    @user, @cluster = create_user_and_cluster_aws

    #
    @node = create_node_status_active(@cluster)

    @cmd = 'stop'
  end


  describe 'Stop node' do

    it 'status' do
      expect(@node.status).to eq 'active'

      # work
      Gexcore::Nodes::Control.stop_node(@node)

      # check
      @node.reload

      expect(@node.status).to eq 'stopped'

    end

    context 'provision' do
      before :each do

      end

      it 'calls provision' do
        # script params
        allow(Gexcore::Provision::Service).to receive(:run) do |task_name, script|
          puts "cmd: #{script}"

          expect(task_name).to eq 'change_aws_node_state_stop'


          #
          expect(script).to match /provision:change_aws_node_state/

          expect(script).to match(/_cluster_id=#{@node.cluster_id}/i)
          expect(script).to match(/_node_id=#{@node.id}/i)
          #expect(script).to match(/_node_uid=#{@node.uid}/i)
          expect(script).to match(/_action=#{@cmd}/i)

        end.and_return(Gexcore::Response.res_data)


        # work
        Gexcore::Nodes::Control.stop_node(@node)

      end

      it 'if error in provision' do
        # error
        allow(Gexcore::Provision::Service).to receive(:run).with('change_aws_node_state_stop', anything).and_return(Gexcore::Response.res_error('test_error', 'test error'))


        # work
        Gexcore::Nodes::Control.stop_node(@node)

        # check
        @node.reload

        expect(@node.status).to eq 'stop_error'
      end
    end

  end



end

