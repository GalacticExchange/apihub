RSpec.describe "Install AWS Node", :type => :request do

  before :each do
    #
    @sysinfo = JSON.parse(File.read('spec/data/node_body.txt'))

    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all

    #
    @user, @cluster = create_user_and_cluster_aws

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
      post_data = {
        clusterID: @cluster.uid,
        nNodes: @n_nodes,
        instanceType: @instance_type
      }

      # work
      post_json '/nodes/add', post_data, {token: @token}

      resp = last_response
      data = response_json

      # check
      node_uid = data['nodes'][0]['nodeID']
      node = Node.get_by_uid node_uid

      expect(node.status).to eq 'installing'

      # gexd: POST /applicationRegistrations
      instance_id = build_instance_id
      post_json '/applicationRegistrations', {"sysinfo" => @sysinfo, "version" => @version, "instanceID" => instance_id}

      resp = last_response
      expect(resp.status).to eq(200)

      #
      node.reload
      agent_token = node.agent_token


      ### run provision
      Gexcore::Nodes::Aws::Provision.create_node(node.id)
      node.reload

      #Gexcore::Nodes::Provision.hadoop_provision_master_create_node(node.id)
      #node.reload
      #Gexcore::Nodes::Aws::Provision.create_node_aws_instance(node.id)
      #node.reload


      ##### gexd setups node

      # gexd: calls API PUT /gexd/nodes
      put_json '/gexd/nodes', {
          nodeID: node.uid,
          instanceID: instance_id,
          sysinfo: @sysinfo,
          agentToken: agent_token,
          #nodeType: nil,
          #hostType: nil,
          # selected_interface: nil,
          # options: nil,
          }

      resp = last_response
      expect(resp.status).to eq(200)


      # get files
      #list of files - provision.rb
      get_json '/files', {clusterID: node.cluster.uid, nodeID: node.uid, module: 'nodeInstall'}, {token: @token}

      resp = last_response
      data = response_json
      expect(resp.status).to eq(200)
      expect(data['files']).not_to be_nil



      # notify NODE_INSTALLED
      post_json '/notify', {
          nodeID: node.uid,
          event: 'NODE_CLIENT_INSTALLED'},
                {token: @token}

      #
      resp = last_response
      data = response_json

      #
      expect(resp.status).to eq 200

      # node status
      node.reload
      expect(node.status).to eq 'starting'


      ######## starting

      # gexd starts the node

      # gexd notifies started
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


    it 'node_client_install_error' do
      post_data = {
          clusterID: @cluster.uid,
          nNodes: 1,
          instanceType: @instance_type
      }

      # work
      post_json '/nodes', post_data, {token: @token}

      resp = last_response
      data = response_json

      # check
      node_uid = data["nodeID"]
      node = Node.get_by_uid node_uid

      expect(node.status).to eq 'installing'

      # gexd: POST /instances
      instance_id = Gexcore::TokenGenerator.generate_invitation_uid
      post_json '/applicationRegistrations', {"sysinfo" => @sysinfo, "version" => @version, "instanceID" => instance_id}

      resp = last_response
      expect(resp.status).to eq(200)

      #
      node.reload
      agent_token = node.agent_token


      # gexd: calls API PUT /gexd/nodes
      put_json '/gexd/nodes', {
          nodeID: node.uid,
          instanceID: instance_id,
          sysinfo: @sysinfo,
          agentToken: agent_token,
          #nodeType: nil,
          #hostType: nil,
          # selected_interface: nil,
          # options: nil,
      }

      resp = last_response
      expect(resp.status).to eq(200)


      # notify NODE_INSTALLED
      post_json '/notify', {
          nodeID: node.uid,
          event: 'NODE_CLIENT_INSTALL_ERROR'},
                {token: @token}

      #
      resp = last_response
      data = response_json

      #
      expect(resp.status).to eq 200

      node.reload
      expect(node.status).to eq 'uninstalling'

    end
  end


end
