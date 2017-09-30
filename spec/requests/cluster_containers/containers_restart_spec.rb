RSpec.describe "Restart container", :type => :request do

  before :each do
    # stub
    stub_create_user_all
    stub_create_cluster_all


    #
    @user, @cluster = create_user_and_cluster_onprem


    #
    @token = auth_token @user

    #
    @cmd = 'restart'
  end

  after :each do

  end



  describe 'put /containers' do

    describe 'Master container' do
      before :each do
        # master container
        @container = @cluster.get_master_container 'hadoop'

      end

      it "status" do
        # precheck
        expect(@container.status).to eq 'active'

        # work
        put_json '/containers', {clusterID: @cluster.uid, containerName: @container.name, command: @cmd}, {token: @token}

        #
        resp = last_response
        data = JSON.parse(resp.body)

        #
        expect(resp.status).to eq 200

        # status
        @container.reload
        expect(@container.status).to eq 'restarting'
      end

    end


    describe 'Slave container' do
      before :each do
        # active node
        stub_create_node_all

        @node = create_node_active(@cluster)

        # container
        @container = Gexcore::Containers::Service.get_slave_by_basename(@node, 'hadoop')

      end


      it 'status' do
        # precheck
        expect(@container.status).to eq 'active'

        # work
        put_json '/containers', {clusterID: @cluster.uid, containerName: @container.name, command: @cmd}, {token: @token}

        #
        resp = last_response
        data = JSON.parse(resp.body)

        #
        expect(resp.status).to eq 200

        # status
        @container.reload
        expect(@container.status).to eq 'restarting'
      end
    end


  end


=begin
  describe 'POST /notify' do

    describe 'Master container' do
      before :each do
        #
        stub_container_provision_all

        # master container
        @container = @cluster.get_master_container 'hadoop'

        # restart
        put_json '/containers', {clusterID: @cluster.uid, containerName: @container.name, command: @cmd}, {token: @token}

        # run provision
        Gexcore::Containers::Provision.run_control_command(@container.id, @cmd)

        @container.reload
      end


      it 'status' do
        # precheck
        expect(@container.status).to eq 'restarting'


        # work - notify from provision script
        post_json '/notify', {event: 'container_restarted', containerID: @container.uid}, {token: @token}

        #
        resp = last_response
        data = JSON.parse(resp.body)

        #
        expect(resp.status).to eq 200

        # check
        @container.reload
        expect(@container.status).to eq 'active'

      end


    end


    describe 'Slave container' do
      before :each do
        #
        stub_container_provision_all

        # active node
        stub_create_node_all

        @node = create_node_active(@cluster)

        # container
        @container = Gexcore::Containers::Service.get_slave_by_basename(@node, 'hadoop')

        # restart
        put_json '/containers', {clusterID: @cluster.uid, containerName: @container.name, command: @cmd}, {token: @token}

        # run provision
        Gexcore::Containers::Provision.run_control_command(@container.id, @cmd)

        @container.reload

      end


      it 'status' do
        # precheck
        expect(@container.status).to eq 'restarting'


        # work - notify from provision script
        post_json '/notify', {event: 'container_restarted', containerID: @container.uid}, {token: @token}

        #
        resp = last_response
        data = JSON.parse(resp.body)

        #
        expect(resp.status).to eq 200

        # check
        @container.reload
        expect(@container.status).to eq 'active'
      end
    end

  end

=end

end
