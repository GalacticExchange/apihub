require 'rspec/expectations'

RSpec.describe "Node names", :type => :request do

  before :each do
    @lib = Gexcore::Nodes::Service
    # create user with cluster
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all
    stub_remove_node_all

    Gexcore::Nodes::Service.rebuild_names

    @node_names_full = Gexcore::Nodes::Service.get_key_node_names_full
    @node_names = Gexcore::Nodes::Service.get_key_node_names

    @user, @cluster = create_user_and_cluster_onprem
  end


  describe 'get name' do
    it 'used names' do
      used_names_count = $redis.scard @node_names

      # get 3 names
      @lib.get_name
      @lib.get_name
      @lib.get_name

      # check
      used_names_count_after = $redis.scard @node_names

      expect(used_names_count).to eq used_names_count_after+3
    end

    it 'all names' do
      all_names_count = $redis.scard @node_names_full

      # get 3 names
      @lib.get_name

      # check
      all_names_count_after = $redis.scard @node_names_full

      # it not change all names in redis
      expect(all_names_count).to eq all_names_count_after
    end

    it 'name is from list' do
      name1 = @lib.get_name

      # check
      expect($redis.sismember @node_names_full, name1).to be true
    end

    it 'name is not available' do
      #
      name1 = @lib.get_name

      # check
      expect($redis.sismember @node_names, name1).to be false
    end

    it 'name2 is different from name1' do
      # user1 uses name1
      name1 = @lib.get_name

      # user2 uses name2
      name2 = @lib.get_name

      #
      expect(name2).not_to eq name1
    end
  end


  describe 'rebuild' do

    it 'name is freed after rebuild' do
      # use name
      name1 = @lib.get_name

      # rebuild manually
      @lib.rebuild_names

      # check
      expect(@lib.is_name_available(name1)).to be true

    end

    it 'name used by node => not available' do
      #
      name = @lib.get_name

      # use name by node
      node = create_node(@cluster, nil, name)


      # rebuild manually
      @lib.rebuild_names


      # check
      expect(@lib.is_name_available(name)).to be false


    end

    it 'name for removed node' do
      #
      name = @lib.get_name

      node = create_node(@cluster, nil, name)

      # remove
      res = Gexcore::Nodes::Service.remove_node(node)
      node.reload

      # rebuild manually
      @lib.rebuild_names

      # check
      expect(@lib.is_name_available(name)).to be true

    end

    it 'rebuild all names if all used' do
      n = $redis.scard @node_names

      puts "available: #{n}"

      1.upto(n) do |ind|
        #puts "#{ind}"
        name = @lib.get_name
      end

      # check nothing left
      n2 = $redis.scard @node_names
      expect(n2).to eq 0


      # check rebuild
      expect(@lib).to receive(:rebuild_names).and_call_original

      name = @lib.get_name

      expect(name).not_to be nil

      expect($redis.scard(@node_names)).to be > 0

    end
  end


  describe 'create node' do
    it 'name is unique' do
      #
      name1 = @lib.get_name

      # create node1
      node1 = create_node(@cluster, nil, name1)
      node1.reload

      expect(node1).not_to be nil
      expect(node1.name).to eq name1

      # create node2 with the same name
      n = Node.count

      node2 = create_node(@cluster, nil, name1)

      n2 = Node.count
      expect(n2).to eq n

      expect(node2).to be nil
    end

  end

  describe 'create two nodes simultaneously' do

    it 'create two nodes' do
      #
      name1 = @lib.get_name
      name2 = @lib.get_name

      # create node2
      node2 = create_node(@cluster, nil, name2)
      node2.reload

      expect(node2).not_to be nil
      expect(node2.name).to eq name2

      # create node1
      node1 = create_node(@cluster, nil, name1)
      node1.reload


      expect(node1).not_to be nil
      expect(node1.name).to eq name1

    end
  end
end
