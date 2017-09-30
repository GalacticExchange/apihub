RSpec.describe "Services info for enterprise cluster", :type => :request do

  describe 'static ips' do
    describe 'hadoop services' do

      before :each do
        # stub
        stub_create_user_all
        stub_create_cluster_all

        # cluster
        @enterprise_options = build_user_options_enterprise
        @enterprise_options[:staticIPs]=true
        @enterprise_options[:networkIPRangeStart]='192.168.0.10'
        @enterprise_options[:networkIPRangeEnd]='192.168.0.50'

        @user_hash = build_user_hash
        @user = create_user_active_and_create_cluster(@user_hash, true, @enterprise_options)
        @cluster = @user.home_cluster


        #
        @token = auth_user_hash(@user_hash)

        # app
        @app_hadoop = @cluster.hadoop_app

      end

      after :each do

      end

      context 'no nodes' do

        it 'get /services' do
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



      end


    end
  end

  describe 'proxy IP' do
    describe 'hadoop services' do

      before :each do
        # stub
        stub_create_user_all
        stub_create_cluster_all

        # cluster
        @enterprise_options = build_user_options_enterprise
        @enterprise_options[:proxyIP]='192.168.0.100'

        @user_hash = build_user_hash
        @user = create_user_active_and_create_cluster(@user_hash, true, @enterprise_options)
        @cluster = @user.home_cluster


        #
        @token = auth_user_hash(@user_hash)

        # app
        @app_hadoop = @cluster.hadoop_app

      end

      after :each do

      end

      context 'no nodes' do

        it 'get /services' do
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

            # !! proxy
            expect(r['socksProxy']['host']).to eq @enterprise_options[:proxyIP]


          end


        end



      end


    end
  end


end
