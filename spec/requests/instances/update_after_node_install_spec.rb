RSpec.describe "update instance", :type => :request do

  before :each do

    # cluster
    @user, @cluster = create_user_and_cluster_onprem

    # node
    stub_create_node_all

    @node_info = JSON.parse(File.read('spec/data/node_body.txt'))
    @node_options = {'selected_interface'=>{'name'=>'eth0'}}
    @post_data = {options: @node_options}


    # auth
    @token = auth_token @user

    # for instance create
    @sysinfo = JSON.parse(File.read('spec/data/node_body.txt'))
    @version = "1.2.3.4"
    @instance_id = build_instance_id
  end

  after :each do

  end

  describe "add instances.last_node_id to DB" do

    describe 'ok' do
      it "ok" do
        # prepare
        post_json '/applicationRegistrations', {"sysinfo" => @sysinfo, "version" => @version, "instanceID" => @instance_id}

        #
        instance = Instance.get_by_uid(@instance_id)

        # create node
        post_json '/nodes', {
            clusterID: @cluster.uid,
            options: @node_options,
            instanceID: @instance_id},
                  {"token" => @token}

        # check
        resp = last_response
        data = response_json

        #
        instance.reload
        node = Node.get_by_uid(data["nodeID"])

        expect(node.id).to eq instance.last_node_id

      end
    end
  end
end
