RSpec.describe "Node install for Cluster with Static IPs", :type => :request do

  before :each do
    @lib = Gexcore::Nodes::Service
    @sysinfo = build_node_sysinfo



  end



  describe "create node with static ip" do

    before :each do
      #
      stub_create_user_all
      stub_create_cluster_all
      stub_create_node_all


      # cluster
      @opts = {
          staticIPs: true,
          networkIPRangeStart: '192.168.0.10',
          networkIPRangeEnd: '192.168.0.50',
      }

      @user, @cluster = create_user_and_cluster_onprem_advanced(@opts)

      #
      allow(@user).to receive(:can?).with(:manage, Cluster).and_return(true)

      #
      @instance_id = build_instance_id
    end


    it "ok - response" do

      # do the work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo)

      # check res
      expect(res.success?).to be_truthy

    end



    it 'allocate IPs for containers' do
      # do the work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo)

      #
      res_data = res.data

      # check
      @cluster.reload

      node = Node.get_by_id(res_data[:node_id])

      #
      containers_names = Gexcore::AppHadoop::App::CONTAINERS_BY_SERVICE_SLAVE.values.uniq


      require 'ipaddr'
      ip_start_int = (IPAddr.new(@opts[:networkIPRangeStart])).to_i
      ip_end_int = (IPAddr.new(@opts[:networkIPRangeEnd])).to_i

      node.containers.each do |r|
        # ip
        expect(r.ip).to be_truthy

        # ip in range
        ip_int = (IPAddr.new(r.ip)).to_i

        expect(ip_int).to be_between(ip_start_int, ip_end_int).inclusive
      end


      # ips should be not available
      ips_created = node.containers.map{|r| r.ip}
      ips_used = Gexcore::Containers::Service.get_ips_allocated_by_containers_in_cluster(node.cluster_id)

      expect(ips_created).to match_array(ips_used)
    end



    it 'calls provision create_node' do
      good_params = ['proxy_ip', 'static_ips', 'gateway_ip', 'network_mask', 'container_ips']
      containers_names = Gexcore::AppHadoop::App::CONTAINERS_BY_SERVICE_SLAVE.values.uniq

      # stub
      allow(Gexcore::Provision::Service).to receive(:run) do |task_name, cmd|
        expect(task_name).to eq 'create_node'

        # options
        good_params.each do |p_good|
          #expect(args[p_good]).not_to be_nil
          expect(cmd_contains_param_name(cmd, p_good)).to eq true
        end

        # ips
        containers_names.each do |cont_name_good|
          #expect(args['container_ips'][cont_name_good]).not_to be_nil
          expect(cmd_contains_param_name(cmd, cont_name_good)).to eq true
        end

      end.and_return(Gexcore::Response.res_data)


      # do the work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo)


    end

  end


  describe 'create node with Static IPs for dedicated server' do
    before :each do

      # prepare
      stub_create_node_all


      # cluster
      @opts = {
          staticIPs: true,
          networkIPRangeStart: '192.168.0.10',
          networkIPRangeEnd: '192.168.0.50',
      }

      @user, @cluster = create_user_and_cluster_onprem_advanced(@opts)


      # node data
      @host_type_name = 'dedicated'
      @node_extra_fields = {host_type_name: @host_type_name }


      #
      @instance_id = build_instance_id

      # stub
      allow(@user).to receive(:can?).with(:manage, Cluster).and_return(true)

    end


    it "ok - response" do

      # do the work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, @node_extra_fields)


      # check res
      expect(res.success?).to be_truthy
      expect(res.data[:node_id]).to be_truthy

    end



    it "Data in DB" do
      # prepare
      node_count = Node.count
      cluster_last_node_number_count = @cluster.last_node_number

      # work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, @node_extra_fields)

      #
      @cluster.reload

      #
      res_data = res.data
      node = Node.get_by_id(res_data[:node_id])

      #
      expect(Node.count).to eq(node_count+1)
      expect(@cluster.last_node_number).to eq(cluster_last_node_number_count+1)

      #
      expect(node).not_to be_nil
      expect(node.uid).not_to be_nil
      expect(node.name).not_to be_nil
      expect(node.cluster_id).to eq(@cluster.id)
      #expect(node.ip).not_to be_empty
      #expect(node.port).to be > 0
      expect(node.host_type.name).to eq @host_type_name
      #expect(node.system_info).to eq(@sysinfo.to_s)# ???

      expect(node.installing?).to eq true



    end

    it 'allocate IPs for containers' do
      # work
      res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo, @node_extra_fields)

      #
      res_data = res.data

      # check
      @cluster.reload
      node = Node.get_by_id(res_data[:node_id])


      #
      containers_names = ['hadoop', 'hue']

      # node containers
      expect(node.containers.count).to eq containers_names.count

      #
      require 'ipaddr'
      ip_start_int = (IPAddr.new(@opts[:networkIPRangeStart])).to_i
      ip_end_int = (IPAddr.new(@opts[:networkIPRangeEnd])).to_i

      node.containers.each do |r|
        # ip
        expect(r.ip).to be_truthy

        # ip in range
        ip_int = (IPAddr.new(r.ip)).to_i

        expect(ip_int).to be_between(ip_start_int, ip_end_int).inclusive
      end


      # ips should be not available
      ips_created = node.containers.map{|r| r.ip}
      ips_used = Gexcore::Containers::Service.get_ips_allocated_by_containers_in_cluster(node.cluster_id)

      expect(ips_created).to match_array(ips_used)
    end
  end



end
