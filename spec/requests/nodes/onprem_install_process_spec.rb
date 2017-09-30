RSpec.describe "Install Node on onprem cluster", :type => :request do

  before :each do
    #
    @sysinfo = JSON.parse(File.read('spec/data/node_body.txt'))

    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    #
    @user, @cluster = create_user_and_cluster_onprem

    #
    @token = auth_token @user

    #
    @n_nodes =1
    @instance_type = 't2.medium'

  end

  after :each do

  end

  describe 'process' do

    it 'from installing to active' do
      @host_type_name = NodeHostType::VIRTUALBOX
      @node_type_name = ClusterType::ONPREM
      @instance_id = build_instance_id
      @node_options =  {}
      #options: {"selected_interface": {name: "eth0", "isWifi"=>true|false} }

      post_data = {
          clusterID: @cluster.uid,
          instanceID: @instance_id,
          hostType: @host_type_name,
          nodeType: @node_type_name,
          systemInfo: build_node_sysinfo,
          options: @node_options,

      }

      # work
      post_json '/nodes', post_data, {token: @token}

      resp = last_response
      data = response_json

      # check
      node_uid = data["nodeID"]
      node = Node.get_by_uid node_uid

      expect(node.status).to eq 'installing'

      #
      agent_token = node.agent_token



      # notify NODE_INSTALLED
      post_json '/notify', {
          nodeID: node.uid,
          event: 'NODE_INSTALLED'},
                {token: @token}

      #
      resp = last_response
      data = response_json

      #
      expect(resp.status).to eq 200

      # node status
      node.reload
      expect(node.status).to eq 'starting'


      # notify started
      post_json '/notify', {
          nodeID: node.uid,
          event: 'NODE_STARTED'},
                {token: @token}

      #
      resp = last_response
      data = response_json

      #
      expect(resp.status).to eq 200

      # node status
      node.reload
      expect(node.status).to eq 'active'

    end


    it 'install_error' do
      @host_type_name = NodeHostType::VIRTUALBOX
      @node_type_name = ClusterType::ONPREM
      @instance_id = build_instance_id
      @node_options =  {}
      #options: {"selected_interface": {name: "eth0", "isWifi"=>true|false} }

      post_data = {
          clusterID: @cluster.uid,
          instanceID: @instance_id,
          hostType: @host_type_name,
          nodeType: @node_type_name,
          systemInfo: build_node_sysinfo,
          options: @node_options,

      }

      # work
      post_json '/nodes', post_data, {token: @token}

      resp = last_response
      data = response_json

      # check
      node_uid = data["nodeID"]
      node = Node.get_by_uid node_uid

      expect(node.status).to eq 'installing'


      # notify NODE_INSTALLED
      post_json '/notify', {
          nodeID: node.uid,
          event: 'NODE_INSTALL_ERROR'},
                {token: @token}

      #
      resp = last_response
      data = response_json

      #
      expect(resp.status).to eq 200

      node.reload
      expect(node.status).to eq 'install_error'

    end
  end


end
