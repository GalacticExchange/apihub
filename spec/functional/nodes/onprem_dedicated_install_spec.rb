RSpec.describe "Node install - Dedicated", :type => :request do
  before :each do
    @sysinfo = build_node_sysinfo
    @lib = Gexcore::Nodes::Service

    #
    stub_create_user_all
    stub_create_cluster_all

    # create user with cluster
    @user, @cluster = create_user_and_cluster_onprem

    #
    @instance_id = build_instance_id
  end


  describe 'create node - of dedicated type' do
    before :each do
      allow(@user).to receive(:can?).with(:manage, Cluster).and_return(true)

      # prepare
      stub_create_node_all


      #
      @host_type_name = 'dedicated'
      @node_extra_fields = {host_type_name: @host_type_name }
    end


    it "ok - response" do

      # do the work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, @node_extra_fields)


      # check res
      expect(res.success?).to be_truthy
      expect(res.data[:node_id]).to be_truthy

    end



    it "DB" do
      # prepare
      node_count = Node.count
      cluster_last_node_number_count = @cluster.last_node_number

      # work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, @node_extra_fields)

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
      expect(node.uid).not_to be_nil
      expect(node.name).not_to be_nil
      expect(node.cluster_id).to eq(@cluster.id)
      #expect(node.ip).not_to be_empty
      #expect(node.port).to be > 0
      expect(node.host_type.name).to eq @host_type_name
      #expect(node.system_info).to eq(@sysinfo.to_s)# ???

      expect(node.installing?).to eq true
    end
  end
end
