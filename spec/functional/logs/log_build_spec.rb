RSpec.describe "Log builder", :type => :request do

  describe 'build_log_hash' do

    before :each do
      @version = '0.1'
      @source = 'api'
    end

    describe 'node' do

      before :each do
        #
        stub_create_user_all
        stub_create_cluster_all
        stub_create_node_all

        # create user with cluster
        @user, @cluster = create_user_and_cluster_onprem

        # stub permissions
        allow(@user).to receive(:can?).with(:manage, Cluster).and_return(true)

        # create node
        @node = create_node_active(@cluster)
      end

      it 'set cluster by node' do
        level = 'debug'

        node = @node
        type_name = "node_state_changed"
        msg = "Node debug"
        data = {
                node_id: node.id,
                #node_uid: node.uid,
                from: 'running',
                to: 'done',
                #event: node.aasm.current_event}
        }

        #
        row = Gexcore::GexLogger.build_log_hash(@version, @source, level, msg, type_name, data)


        x = 0
        #expect(row[:cluster_id])

      end
    end

  end


end



