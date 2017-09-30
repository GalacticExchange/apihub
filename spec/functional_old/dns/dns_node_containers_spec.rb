RSpec.describe "DNS for Containers on Node", :type => :request do
  before :each do
    @sysinfo = JSON.parse(File.read('spec/data/node_body.txt'))

    #
    @lib = Gexcore::DnsService

    stub_create_user_all
    stub_create_cluster_all



    # servers data
    @zone = Gexcore::Settings.domain_zone


  end


  describe 'Services on Node' do
    before :each do
      # create user with cluster
      @admin = create_user_active_and_create_cluster
      @cluster = @admin.home_cluster

      # install node
      stub_create_node_all

      @node = create_node(@cluster)



    end


    describe 'calc IPs for node' do

    end

    describe 'calc domains for node' do

    end

    describe 'IP by domain for node' do

    end

    describe 'Domain by IP for node' do

    end


    describe 'update IP' do
      before :each do
        @node_data = {
            cluster_id: @cluster.uid,
            node_id: @node.uid,
        }

        # stub ansible
        allow(Gexcore::ProvisionService).to receive(:update_container_route).and_return(Gexcore::Response.res_data)

      end

      it 'ok - data in DB' do
        container_basename = 'hadoop'
        domain = Gexcore::AppHadoopSlaveContainer.calc_domain(container_basename, @node)
        ip = '51.99.98.97'

        res = Gexcore::Containers::Service.update_ip_for_container_node(domain, ip, @node_data)

        expect(res.success?).to eq true

        # get from DB
        row = ClusterContainer.get_by_node(container_basename, @node)

        expect(row.ip).to eq ip

      end

      it 'invalidate cache' do
        container_name = 'hadoop'
        domain = Gexcore::AppHadoopSlaveContainer.calc_domain(container_name, @node)

        #
        ip = Faker::Internet.ip_v4_address
        res = Gexcore::Containers::Service.update_ip_for_container_node(domain, ip, @node_data)

        #res = Gexcore::ClusterServices::Service.get_ip_by_domain(domain)
        #res_ip_old = res.data[:ip]


        # update again
        ip_new = Faker::Internet.ip_v4_address
        res = Gexcore::Containers::Service.update_ip_for_container_node(domain, ip_new, @node_data)

        # check cache
        ip_cache = Gexcore::DnsService.cache_get_domain_ip(domain)
        expect(ip_cache).to be_nil

        # get ip
        res = Gexcore::DnsService.get_ip_by_domain(domain)
        res_ip = res.data[:ip]

        expect(res_ip).to eq ip_new


      end


      it 'calls ansible ' do
        # init
        container_name = 'hadoop'
        domain = Gexcore::AppHadoopSlaveContainer.calc_domain(container_name, @node)
        ip = '51.99.98.97'

        # expect
        expect(Gexcore::Provision::Service).to receive(:update_container_route).with(kind_of(Node), ip).and_return(Gexcore::Response.res_data)

        # do
        res = Gexcore::Containers::Service.update_ip_for_container_node(domain, ip, @node_data)

        expect(res.success?).to eq true

      end


      it 'duplicate IP' do
        require 'ipaddr'
        ip = "%d.%d.%d.%d" % [rand(256), rand(256), rand(256), rand(256)]


        # node1
        container_name = 'hadoop'
        domain = Gexcore::AppHadoopSlaveContainer.calc_domain(container_name, @node)

        res = Gexcore::Containers::Service.update_ip_for_container_node(domain, ip, @node_data)


        # node 2
        node2 = create_node(@cluster)
        container_name = 'hadoop'
        domain2 = Gexcore::AppHadoopSlaveContainer.calc_domain(container_name, node2)

        node_data2 = @node_data.clone
        node_data2[:node_id] = node2.uid

        res = Gexcore::Containers::Service.update_ip_for_container_node(domain2, ip, node_data2)

        # data in DB
        c1 = ClusterContainer.get_by_node(container_name, @node)
        c2 = ClusterContainer.get_by_node(container_name, node2)

        c1_ip = c1.ip || ''
        expect(c1_ip).to eq ''

        expect(c2.ip).to eq ip
      end
    end

  end


  describe 'Reverse DNS - misc' do

    it 'nil IP' do
      ip = nil
      res_domain = @lib.domain_by_ip(ip)

      expect(res_domain).to be_nil
    end

  end

end
