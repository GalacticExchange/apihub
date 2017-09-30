RSpec.describe "Nodes properties info", :type => :request do

  before :each do
    # stub
    stub_create_cluster_all
    stub_create_node_all

    #
    @user, @cluster = create_user_active_and_create_cluster

    @username = @user.username

    # install node
    @node = create_node(@cluster)

    #
    @token = auth_token @user
  end


  describe "GET /nodePropertiesInstall" do

    it "ok" do
      # stub props vpn
      ['client_ip', 'server_ip', 'port'].each do |s|
        allow(Gexcore::ClusterInfoService).to receive(:get_node_property_vpn).with(kind_of(Node), s).and_return('xx.xx')
      end


      # work
      get_json '/nodePropertiesInstall', {nodeID: @node.uid}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      #expect(data['node']).to be_truthy

      #
      #node = data['node']
      node = data

      expect(node['node_id']).to be_truthy
      expect(node['node_name']).to be_truthy
      expect(node['node_uid']).to be_truthy

      expect(node['sensu_name']).to be_truthy
      expect(node['sensu_node_id']).to be_truthy
      expect(node['sensu_rmquser']).to be_truthy
      expect(node['sensu_rmqpwd']).to be_truthy
      expect(node['sensu_rmqhost']).to be_truthy

      expect(node['vpn_client_ip']).to be_truthy
      expect(node['vpn_server_ip']).to be_truthy
      expect(node['vpn_server_port']).to be_truthy

    end

  end


  describe "GET /nodePropertiesInstall with enterprise options" do

    it "ok" do
      # work
      get_json '/nodePropertiesInstall', {nodeID: @node.uid}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      #expect(data['node']).to be_truthy

      #
      #node = data['node']
      node = data

      expect(node['node_id']).to be_truthy
      expect(node['node_name']).to be_truthy
      expect(node['node_uid']).to be_truthy

      expect(node['sensu_name']).to be_truthy
      expect(node['sensu_node_id']).to be_truthy
      expect(node['sensu_rmquser']).to be_truthy
      expect(node['sensu_rmqpwd']).to be_truthy
      expect(node['sensu_rmqhost']).to be_truthy

      # enterprise options
      #expect(node['proxy_ip']).to be_truthy
      #expect(node['static_ips']).to be_truthy
      #expect(node['gateway_ip']).to be_truthy
      #expect(node['network_mask']).to be_truthy
      #expect(node['container_ips']).to be_truthy

      #
      [
          'openvpn_port',
          'openvpn_ip_address',
          'vpn_client_ip',
          'vpn_server_ip',
          'vpn_server_port'
      ].each do |f|
        expect(node.has_key?(f)).to be_truthy
      end

    end

  end

end
