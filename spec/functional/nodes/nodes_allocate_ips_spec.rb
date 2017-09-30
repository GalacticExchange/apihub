RSpec.describe "Allocate static IPs for node containers", :type => :request do

  before :each do
    @lib = Gexcore::Nodes::Service
    @sysinfo = build_node_sysinfo

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

    # stub rabbitmq operations
    stub_node_remove_rabbitmq
  end


  it 'allocate first available IPs for container' do
    # install node 1
    @instance_id_1 = build_instance_id
    res = @lib.create_node_by_user(@instance_id_1, @user, @cluster, @sysinfo)
    node1 = Node.get_by_id(res.data[:node_id])

    #
    ips_node1 = node1.containers.map{|r| r.ip}
    ips_used_1 = Gexcore::Containers::Service.get_ips_allocated_by_containers_in_cluster(@cluster.id)

    # install our node
    @instance_id_2 = build_instance_id
    res = @lib.create_node_by_user(@instance_id_2, @user, @cluster, @sysinfo)
    node = Node.get_by_id(res.data[:node_id])

    # IPs should be different from IPs for node1
    ips_node = node.containers.map{|r| r.ip}

    ips_node.each do |v|
      expect(ips_node1.include?(v)).to eq false
    end

    # allocate more ips
    ips_used = Gexcore::Containers::Service.get_ips_allocated_by_containers_in_cluster(@cluster.id)

    expect(ips_used.count).to be > ips_used_1.count

  end

  it 'release IPs for removed node' do
    # install node1
    @instance_id_1 = build_instance_id
    res = @lib.create_node_by_user(@instance_id_1, @user, @cluster, @sysinfo)
    node = Node.get_by_id(res.data[:node_id])

    ips_used_old = Gexcore::Containers::Service.get_ips_allocated_by_containers_in_cluster(@cluster.id)

    # remove node
    Gexcore::Nodes::Service.remove_node(node)


    # check
    ips_used = Gexcore::Containers::Service.get_ips_allocated_by_containers_in_cluster(@cluster.id)

    expect(ips_used.count).to be < ips_used_old.count

    ips_used_old.each do |ip|
      expect(ips_used.include?(ip)).to eq false
    end
  end


  it 'allocate IP for removed node' do
    # install node1
    @instance_id_1 = build_instance_id
    res = @lib.create_node_by_user(@instance_id_1, @user, @cluster, @sysinfo)
    node1 = Node.get_by_id(res.data[:node_id])

    ips_node1 = node1.containers.map{|r| r.ip}


    # install node2
    @instance_id_2 = build_instance_id
    res = @lib.create_node_by_user(@instance_id_2, @user, @cluster, @sysinfo)
    node2 = Node.get_by_id(res.data[:node_id])

    ips_node2 = node2.containers.map{|r| r.ip}

    # remove node1
    res_remove_node1 = Gexcore::Nodes::Service.remove_node(node1)


    # before work
    ips_used_old = Gexcore::Containers::Service.get_ips_allocated_by_containers_in_cluster(@cluster.id)


    # install our node
    @instance_id = build_instance_id
    res = @lib.create_node_by_user(@instance_id, @user, @cluster, @sysinfo)
    node = Node.get_by_id(res.data[:node_id])

    # check
    ips_node = node.containers.map{|r| r.ip}

    # IPs should be different from IPs for node2
    ips_node.each do |v|
      expect(ips_node2.include?(v)).to eq false
    end

    # IPs should be used from node1
    ips_node.each do |v|
      expect(ips_node1.include?(v)).to eq true
    end

  end

end


