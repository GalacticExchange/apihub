RSpec.describe "Node remove", :type => :request do

  before :each do
    # stub
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all
    stub_remove_node_all

    # create user with cluster
    @user, @cluster = create_user_and_cluster_onprem
  end


  describe 'remove active node' do
    before :each do
      # active node
      @node = create_node_active(@cluster)
    end


    it 'ok' do
      # prepare
      expect(@node.active?).to eq true


      #
      res = Gexcore::Nodes::Service.remove_node @node

      # check
      @node.reload

      #
      expect(res.success?).to eq true

      expect(@node.removed?).to eq true

    end



    it 'remove_error' do
      # stub - cannot delete data on rabbitmq
      expect(Gexcore::Nodes::Control).to receive(:rabbitmq_delete_all_for_node).and_return Gexcore::Response.res_error('test_error', 'TEST error')


      # work
      Gexcore::Nodes::Service.remove_node(@node)

      #
      @node.reload

      expect(@node.remove_error?).to eq true
    end



    it 'method remove_node - calls rabbitmq_delete_all_for_node' do
      expect(Gexcore::Nodes::Control).to(
          receive(:rabbitmq_delete_all_for_node)
              .with(anything)
              .and_return(Gexcore::Response.res_data)
      )

      # work
      Gexcore::Nodes::Service.remove_node @node

      # check
      @node.reload

    end


    it 'removes containers' do
      # work
      Gexcore::Nodes::Service.remove_node @node

      # check
      @node.reload

      rows_containers = @node.containers.w_not_deleted.all
      #rows_containers = ClusterContainer.where(node_id: @node.id).all

      expect(rows_containers.count).to eq 0
    end


    it 'removes services' do
      # work
      res = Gexcore::Nodes::Service.remove_node @node

      # check
      expect(res.success?).to eq true

      @node.reload

      # containers
      rows= @node.containers.all
      rows.each do |r|
        expect(r.status).to eq 'removed'
      end

      # services
      rows= @node.services.all
      rows.each do |r|
        expect(r.status).to eq 'removed'
      end
    end

  end



  describe 'remove remove_error node' do
    it 'remove again for remove_error node' do
      # prepare
      node = create_node_status_remove_error(@cluster)
      expect(node.status).to eq 'remove_error'

      # work
      Gexcore::Nodes::Service.remove_node(node)

      #
      node.reload

      expect(node.status).to eq 'removed'

    end
  end

  describe 'delete RabbitMQ data' do

    it 'no RabbitMQ data' do
      #
      require "rabbitmq/http/client"


      # prepare
      node = create_node_status_remove_error(@cluster)
      expect(node.status).to eq 'remove_error'

      # stub rabbitmq
      allow_any_instance_of(RabbitMQ::HTTP::Client).to receive(:delete_queue).and_return true
      allow_any_instance_of(RabbitMQ::HTTP::Client).to receive(:delete_exchange).and_return true

      # error in deleting user
      allow_any_instance_of(RabbitMQ::HTTP::Client).to receive(:delete_user).and_raise(Faraday::ResourceNotFound.new('ups'))

      # work
      res = Gexcore::Nodes::Control.rabbitmq_delete_all_for_node(node)

      #
      expect(res.success?).to eq true


    end
  end
end
