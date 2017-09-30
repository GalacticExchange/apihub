RSpec.describe "Nodes", :type => :request do
  before :each do
    # stub
    stub_create_cluster_all
    stub_create_node_all

    #
    @user, @cluster = create_user_active_and_create_cluster

    # install node
    @node = create_node(@cluster)

    #
    @token = auth_token @user

  end

  after :each do

  end

  describe "GET /nodeState" do

  it 'node state' do
    # work
    get_json '/nodeState', {nodeID: @node.uid}, {token: @token}

    #
    resp = last_response
    data = JSON.parse(resp.body)

    expect(resp.status).to eq 200

    #
    expect(data['node']).to be_truthy

    #
    node = data['node']

    expect(node['id']).to be_truthy
    expect(node['status']).to be_truthy
    expect(node['state']).to be_truthy
    expect(node['status_changed']).to be >0
    expect(node['hostType']).to be_truthy
  end

  it 'get by NodeAgent' do
    # work
    get_json '/nodeState', {nodeID: @node.uid}, {nodeAgentToken: @node.agent_token}

    #
    resp = last_response
    data = JSON.parse(resp.body)

    #
    expect(data['node']).to be_truthy

    #
    node = data['node']

    expect(node['id']).to be_truthy
    expect(node['status']).to be_truthy
    expect(node['state']).to be_truthy
    expect(node['hostType']).to be_truthy
  end

  it 'not exists node' do
    # random node uid
    node_uid = Gexcore::Nodes::Service.generate_uid

    # work
    get_json '/nodeState', {nodeID: node_uid}, {token: @token}

    #
    resp = last_response
    data = JSON.parse(resp.body)

    expect(resp.status).to eq 404

  end

end

end
