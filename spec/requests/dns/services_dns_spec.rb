RSpec.describe "DNS for services", :type => :request do
  before :each do
    # user - create cluster
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all
    stub_create_app_all

    #
    @zone = Gexcore::Settings.domain_zone
  end


  describe 'GET /serviceIP' do

=begin
    describe 'our servers' do
      before :each do
        @test_data = {
            'master' => {domain: "master.#{@zone}"}
        }

        @test_data.each do |name, r|
          @test_data[name][:ip] = Gexcore::Settings.config_servers[name]['ip']
        end
      end

      describe 'IPs by domain' do
        it 'get ip' do
          @test_data.each do |name, r|
            get_json '/serviceIp', {domain: r[:domain]}, {}

            #
            resp = last_response
            resp_data = JSON.parse(resp.body)

            expect(resp_data['ip']).to eq r[:ip]
          end

        end

      end

      describe 'Domain by IP' do
        it 'get domain' do
          @test_data.each do |name, r|
            get_json '/serviceIp', {ip: r[:ip], t: 'ip'}, {}

            #
            resp = last_response
            resp_data = JSON.parse(resp.body)

            expect(resp_data['domain']).to eq r[:domain]
          end

        end

      end
    end
=end

    describe 'Services on master' do
      before :each do
        #
        @admin_hash = build_user_hash
        @admin = create_user_active_and_create_cluster @admin_hash
        @cluster = @admin.home_cluster

        # install cluster
        #Gexcore::ProvisionService.create_cluster_run_script @cluster.id

        # auth main user
        @token = auth_user_hash(@admin_hash)

        #
        @test_data = []
        @test_data << {
            ip: Gexcore::AppHadoop::MasterContainer.calc_ip('hadoop', @cluster),
            domain: Gexcore::AppHadoop::MasterContainer.calc_domain('hadoop', @cluster)
        }
        @test_data << {
            ip: Gexcore::AppHadoop::MasterContainer.calc_ip('hue', @cluster),
            domain: Gexcore::AppHadoop::MasterContainer.calc_domain('hue', @cluster)
        }

      end


      describe 'IP by domain' do

        it 'get IP by domain' do

          @test_data.each do |r|
            get_json '/serviceIp', {domain: r[:domain]}, {}

            #
            resp = last_response
            resp_data = JSON.parse(resp.body)

            #
            ip = resp_data['ip']
            expect(ip).to match r[:ip]

          end

        end


      end

      describe 'Domain by IP' do

        it 'get domain by ip' do

          @test_data.each do |r|
            get_json '/serviceIp', {ip: r[:ip], t: 'ip'}, {}

            #
            resp = last_response
            resp_data = JSON.parse(resp.body)

            #
            domain = resp_data['domain']
            expect(domain).to match r[:domain]

          end

        end

      end

    end

  end

  describe 'POST /serviceIP' do


    describe 'services on node' do
      before :each do
        #
        @admin_hash = build_user_hash
        @admin = create_user_active_and_create_cluster @admin_hash
        @cluster = @admin.home_cluster

        # install cluster
        #Gexcore::Clusters::Service.create_cluster_run_script @cluster.id

        # create node
        stub_create_node_all

        @node = create_node(@cluster)

        #
        @token = auth_user_hash(@admin_hash)

      end

      it 'update IP' do
        container_name = 'hadoop'
        domain = Gexcore::AppHadoopSlaveContainer.calc_domain(container_name, @node)
        ip = '51.99.98.97'


        post_json '/serviceIp', {domain: domain, ip: ip, clusterID: @cluster.uid, nodeID: @node.uid}, {}

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        # data in DB
        row = ClusterContainer.get_by_node(container_name, @node)

        expect(row.ip).to eq ip



      end

      it 'invalidate cache' do
        container_basename = 'hadoop'
        domain = Gexcore::AppHadoopSlaveContainer.calc_domain(container_basename, @node)

        #
        ip = Faker::Internet.ip_v4_address
        post_json '/serviceIp', {domain: domain, ip: ip, clusterID: @cluster.uid, nodeID: @node.uid}, {}

        # update again
        ip_new = Faker::Internet.ip_v4_address
        post_json '/serviceIp', {domain: domain, ip: ip_new, clusterID: @cluster.uid, nodeID: @node.uid}, {}

        # check
        get_json '/serviceIp', {domain: domain}, {}

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        expect(resp_data['ip']).to eq ip_new
      end


      it 'clear old domain for the same IP' do
        require 'ipaddr'
        #ip= IPAddr.new(rand(2**32),Socket::AF_INET)
        ip = "%d.%d.%d.%d" % [rand(256), rand(256), rand(256), rand(256)]
        #ip = '51.99.98.97'


        # node1
        container_name = 'hadoop'
        domain = Gexcore::AppHadoopSlaveContainer.calc_domain(container_name, @node)

        post_json '/serviceIp', {domain: domain, ip: ip, clusterID: @cluster.uid, nodeID: @node.uid}, {}


        # precheck. get node1 IP
        resp = get_json '/serviceIp', { domain: domain }, {}

        #
        expect(resp['ip']).to eq ip


        # node 2
        node2 = create_node(@cluster)
        container_name = 'hadoop'
        domain2 = Gexcore::AppHadoopSlaveContainer.calc_domain(container_name, node2)

        resp = post_json '/serviceIp', {domain: domain2, ip: ip, clusterID: @cluster.uid, nodeID: node2.uid}, {}


        # data in DB
        c1 = ClusterContainer.get_by_node(container_name, @node)
        c2 = ClusterContainer.get_by_node(container_name, node2)

        c1_ip = c1.ip || ''
        expect(c1_ip).to eq ''

        expect(c2.ip).to eq ip


        # step2. get node1 IP
        resp = get_json '/serviceIp', { domain: domain }, {}

        #
        resp_ip = resp['ip'] || ''
        expect(resp_ip).to eq ''


        # check. node2 IP
        resp = get_json '/serviceIp', { domain: domain2 }, {}

        #
        expect(resp['ip']).to eq ip

      end
    end

    describe 'services on app' do
      before :each do
        # user, cluster, node
        @user, @cluster = create_user_active_and_create_cluster
        @node = create_node(@cluster)

        # app
        @app_library = get_random_library_app_not_hadoop
        @app_name = @app_library.name
        @app_settings = build_app_settings

        res = Gexcore::Applications::Service.install_application_by_user(@user, @app_name, @node.uid, @app_settings)

        #
        @token = auth_token(@user)

      end

      it 'update IP' do
        # init
        container_name = Gexcore::Applications::Service.build_container_name_for_application(@app_name, @node)
        domain = Gexcore::Applications::Service.container_calc_domain_by_name(container_name)

        # any ip from the client
        ip = '51.99.98.97'

        post_json '/serviceIp', {domain: domain, ip: ip, clusterID: @cluster.uid, nodeID: @node.uid}, {}

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        # data in DB
        row = ClusterContainer.get_by_node(@app_name, @node)

        expect(row.ip).to eq ip



      end
    end

  end

end
