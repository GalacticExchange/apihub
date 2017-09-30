RSpec.describe "Create Node", :type => :request do

  before :each do
    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    #
    @user, @cluster = create_user_and_cluster_onprem

    # auth
    @token = auth_token @user
  end

  after :each do

  end

  describe "create node" do
    before :each do
      @host_type_name = NodeHostType::DEFAULT_NAME
      @node_type_name = ClusterType::ONPREM
      @instanceID = build_instance_id
      @node_options =  {}

      #@post_data = @node_info.merge({'hostType'=>@host_type_name})
      @post_data = {
          clusterID: @cluster.uid,
          instanceID: @instanceID,
          hostType: @host_type_name,
          nodeType: @node_type_name,
          systemInfo: build_node_sysinfo,
          options: @node_options,

      }
    end

    describe 'ok' do
      it "ok" do
        # work
        post_json '/nodes', @post_data, {"token" => @token}

        #
        resp = last_response
        data = response_json

        # check
        expect(data["clusterID"]).not_to be_empty
        expect(data["nodeID"]).not_to be_empty
        expect(data["nodeName"]).not_to be_empty
        expect(data["nodeNumber"].to_s).not_to be_empty
        expect(data["hostType"].to_s).to eq @host_type_name
        expect(data["nodeAgentToken"].to_s).not_to be_empty
        expect(data["hadoopType"].to_s).not_to be_empty

      end
    end



    describe 'if ansible error' do

      it 'install_error' do
        # error in ansible
        allow(Gexcore::Provision::Service).to(
            receive(:run)
                .with('create_node', any_args)
                .and_return(Gexcore::Response.res_error('test_error_node', 'test error'))
        )

        n_nodes = Node.count

        # work
        post_json '/nodes', @post_data, {token: @token}

        #
        resp = last_response
        data = response_json

        #
        expect(resp.status).to eq 500

        #
        expect(Node.count).to eq n_nodes+1

        # node
        @cluster.reload
        node = @cluster.nodes[0]

        expect(node.status).to eq 'install_error'

      end
    end


  end




  describe 'create node - options' do
    before :each do
      @host_type_name = NodeHostType::DEFAULT_NAME
      @node_type_name = ClusterType::ONPREM
      @instanceID = build_instance_id
      @node_options =  build_node_options

      @post_data = {
          clusterID: @cluster.uid,
          instanceID: @instanceID,
          hostType: @host_type_name,
          nodeType: @node_type_name,
          systemInfo: build_node_sysinfo,
          options: @node_options,

      }
    end

    it 'ok' do

      # work
      post_json '/nodes', @post_data, {token: @token}

      #
      resp = last_response
      data = response_json

      # check
      node_uid = data["nodeID"]
      node = Node.get_by_uid node_uid

      # data in DB
      expect(node.options_hash['selected_interface']).not_to be_nil
      expect(node.options_hash['selected_interface']['name']).to eq @node_options['selected_interface']['name']


    end
  end


  describe "create node - of dedicated type" do
    before :each do
      @host_type_name = NodeHostType::DEDICATED
      @node_type_name = ClusterType::ONPREM
      @instanceID = build_instance_id
      @node_options =  {}

      @post_data = {
          clusterID: @cluster.uid,
          instanceID: @instanceID,
          hostType: @host_type_name,
          nodeType: @node_type_name,
          systemInfo: build_node_sysinfo,
          options: @node_options,

      }
    end

    describe 'ok' do
      it "ok" do
        # work
        post_json '/nodes', @post_data, {token: @token}

        #
        resp = last_response
        data = JSON.parse(resp.body)

        # expectation
        expect(data["clusterID"]).not_to be_empty
        expect(data["nodeID"]).not_to be_empty
        expect(data["nodeName"]).not_to be_empty
        expect(data["nodeNumber"].to_s).not_to be_empty
        expect(data["hostType"].to_s).to eq @host_type_name
        expect(data["nodeAgentToken"].to_s).not_to be_empty
        #expect(data["gatewayIP"]).not_to be_empty

      end
    end
  end



end
