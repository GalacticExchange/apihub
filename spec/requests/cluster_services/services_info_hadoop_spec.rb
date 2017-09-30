RSpec.describe "Services info for Hadoop", :type => :request do

  before :each do
    # user - create cluster
    stub_create_cluster_all

    #
    @admin_hash = build_user_hash
    @admin = create_user_active_and_create_cluster @admin_hash
    @cluster = @admin.home_cluster

    # app
    @app_hadoop = @cluster.hadoop_app

    # auth main user
    @token = auth_user_hash(@admin_hash)
  end

  after :each do

  end

  context 'no nodes' do
    it 'get /services for hadoop' do
      # work
      get_json '/services', {clusterID: @cluster.uid, applicationID: @app_hadoop.uid}, {token: @token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      services = resp_data['services']
      expect(services.count).to be > 0

      services_good = Gexcore::AppHadoop::SERVICES_MASTER.keys
      expect(services.count).to eq services_good.count


      services.each do |r|
        expect(services_good).to include r['name']

        expect(r['name']).to be_truthy
        expect(r['containerName']).to be_truthy

        expect(r['masterContainer']).to eq true
        expect(r['nodeName']).to be_falsey

        #expect(r['public_ip']).to be_truthy
        expect(r['host']).to be_truthy
        expect(r['port']).to be_truthy
        expect(r['protocol']).to be_truthy

      end

    end


    context 'node' do
      before :each do
        # install node
        stub_create_node_all

        #
        @node = create_node(@cluster)

        # auth main user
        @token = auth_user_hash(@admin_hash)

      end

      it 'list services' do
        # work
        get_json '/services', {clusterID: @cluster.uid, applicationID: @app_hadoop.uid, nodeID: @node.uid}, {token: @token}

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        #
        services = resp_data['services']
        expect(services.count).to be > 0

        good_services_master_names = Gexcore::AppHadoop::SERVICES_MASTER.keys
        good_services_slave_names = Gexcore::AppHadoop::SERVICES_SLAVE.keys


        services.each do |r|
          expect(r['name']).to be_truthy

          if  r['masterContainer']
            expect(good_services_master_names).to include r['name']
            expect(r['nodeName']).to be_falsey
          else
            # node container
            expect(good_services_slave_names).to include r['name']

            expect(r['nodeName']).to be_truthy

          end

          expect(r['containerName']).to be_truthy

          #expect(r['public_ip']).to be_truthy
          expect(r['host']).to be_truthy
          expect(r['port']).to be_truthy
          expect(r['protocol']).to be_truthy

        end
      end

      it 'bad node uid' do
        #
        node_uid = @node.uid+'000'

        # work
        get_json '/services', {clusterID: @cluster.uid, applicationID: @app_hadoop.uid, nodeID: node_uid}, {token: @token}


        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        #
        expect(resp.status).to eq 400
        expect(resp_data['services']).to be_falsey
        #expect(resp_data['services'].count).to be_falsey

      end


    end

  end

end
