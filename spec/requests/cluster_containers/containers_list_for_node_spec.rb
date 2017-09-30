RSpec.describe "Containers for Node", :type => :request do

  before :each do
    # user
    @user, @cluster = create_user_and_cluster_onprem

    #
    @app, @node = create_app_active(@user)


    # auth
    @token = auth_token @user



  end

  after :each do

  end


  describe 'list for node' do
    it 'get /containers' do
      #
      get_json '/containers', {nodeID: @node.uid}, {token: @token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      containers = resp_data['containers']
      expect(containers.count).to be > 0

      containers.each do |r|
        expect(r['id']).to be_truthy
        expect(r['name']).to be_truthy
        expect(r['nodeName']).to be_truthy
        expect(r['status']).to be_truthy
        expect(r['nodeID']).to be_truthy
        expect(r['applicationName']).to be_truthy
        expect(r['domainname']).to be_truthy
        expect(r['public_ip']).to be nil
        expect(r['masterContainer']).to eq false
      end
    end

=begin
    it 'get 400 if node.uid blank' do
      #
      get_json '/containers', {nodeID: ""}, {token: @token}
      #
      resp = last_response
      #
      expect(resp.status).to eq 400
    end
=end

  end

end
