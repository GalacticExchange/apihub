RSpec.describe "Node fix status", :type => :request do

  before :each do
    @sysinfo = build_node_sysinfo
    @lib = Gexcore::Nodes::Service

    #
    stub_create_user_all
    stub_create_cluster_all

    # create user with cluster
    @user, @cluster = create_user_and_cluster_onprem

    @instance_id = build_instance_id
  end

  describe 'no response from client - fix installing in 1 hour' do
    before :each do
      #
      stub_create_node_all

      # prepare
      allow(@user).to receive(:can?).with(:manage, Cluster).and_return(true)

      # create node
      res = @lib.create_node(@instance_id, @cluster, @sysinfo)
      @node = Node.get_by_id(res.data[:node_id])

    end

    it 'set install_error in 1 hour' do
      # prepare
      expect(@node.status).to eq 'installing'

      # work
      Timecop.freeze(2.hours.from_now) do
        # run sidekiq job
        Gexcore::Nodes::Service.fix_node_status(@node, 'installing', 'install_error')

        # check
        @node.reload

        expect(@node.status).to eq 'install_error'
      end


    end
  end

end
