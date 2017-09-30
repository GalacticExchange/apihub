RSpec.describe "add instance", :type => :request do

  before :each do
    #
    #stub_create_cluster_all

    #
  end


  describe 'instance' do

    before :each do
      #
      #@admin_hash = build_user_hash
      #@admin = create_user_active_and_create_cluster @admin_hash

      # auth main user
      #@token = auth_user(@admin.username, @admin_hash[:password])

      @sysinfo = JSON.parse(File.read('spec/data/node_body.txt'))

      @version = "1.2.3.4"

      @instance_id = build_instance_id

    end

    after :each do

    end


    describe 'success path' do

      it "ok - response" do
        # prepare

        # work
        post_json '/applicationRegistrations', {"sysinfo" => @sysinfo, "version" => @version, "instanceID" => @instance_id}#, {"token" => @token}

        resp = last_response

        # expectation
        expect(resp.status).to eq(200)

      end



      it "add instance to DB" do
        # prepare
        count = Instance.count

        # work
        post_json '/applicationRegistrations', {"sysinfo" => @sys_info, "version" => @version, "instanceID" => @instance_id}#, {"token" => @token}

        #
        resp = last_response
        #resp_data = JSON.parse(resp.body)

        # expectation
        expect(Instance.count).to eq(count + 1)
      end

    end
  end
end
