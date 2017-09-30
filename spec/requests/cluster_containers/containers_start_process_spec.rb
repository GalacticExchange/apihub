RSpec.describe "Start container", :type => :request do

  before :each do
    # stub
    stub_create_user_all
    stub_create_cluster_all


    #
    @user, @cluster = create_user_and_cluster_onprem


    #
    @token = auth_token @user

    #
    @cmd = 'start'

  end

  after :each do

  end


  describe 'Process start master container' do
    before :each do
      # master container
      @container = create_master_container_status_stopped(@cluster, 'hadoop')

    end

    it 'OK' do
      # precheck
      @container.reload
      expect(@container.status).to eq 'stopped'


      # work
      put_json '/containers', {clusterID: @cluster.uid, containerName: @container.name, command: @cmd}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      # status
      @container.reload
      expect(@container.status).to eq 'starting'

      # run provision
      allow(Gexcore::Containers::Provision).to receive(:run_script).and_return(Gexcore::Response.res_data)

      Gexcore::Containers::Provision.run_control_command(@container.id, @cmd)

      # status
      @container.reload
      expect(@container.status).to eq 'active'


=begin
      # status
      @container.reload
      expect(@container.status).to eq 'starting'


      # notify from provision script
      post_json '/notify', {event: 'container_started', containerID: @container.uid}, {token: @token}

      # check
      @container.reload
      expect(@container.status).to eq 'active'
=end


    end

    it 'process - error in provision' do
      # work
      put_json '/containers', {clusterID: @cluster.uid, containerName: @container.name, command: @cmd}, {token: @token}

      # status
      @container.reload
      expect(@container.status).to eq 'starting'

      # error in provision
      allow(Gexcore::Containers::Provision).to receive(:run_script).and_return(Gexcore::Response.res_error("test_error", "err"))

      Gexcore::Containers::Provision.run_control_command(@container.id, @cmd)

      # check
      @container.reload
      expect(@container.status).to eq 'start_error'


=begin
      # status
      @container.reload
      expect(@container.status).to eq 'starting'


      # notify from provision script
      post_json '/notify', {event: 'container_start_error', containerID: @container.uid}, {token: @token}

      # check
      @container.reload
      expect(@container.status).to eq 'start_error'
=end


    end
  end




  describe 'Process start slave container' do

    before :each do
      # active node
      stub_create_node_all

      @node = create_node_active(@cluster)

      # container
      stub_container_provision_all

      @container = create_slave_container_status_stopped(@node, 'hadoop')


    end


    it 'OK' do
      # precheck
      expect(@container.status).to eq 'stopped'

      # work
      put_json '/containers', {clusterID: @cluster.uid, containerName: @container.name, command: @cmd}, {token: @token}

      #
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      # status
      @container.reload
      expect(@container.status).to eq 'starting'

      # run provision
      allow(Gexcore::Containers::Provision).to receive(:run_script).and_return(Gexcore::Response.res_data)

      Gexcore::Containers::Provision.run_control_command(@container.id, @cmd)

      # check
      @container.reload
      expect(@container.status).to eq 'active'


=begin
      # status
      @container.reload
      expect(@container.status).to eq 'starting'


      # notify from provision script
      post_json '/notify', {event: 'container_started', containerID: @container.uid}, {token: @token}

      # check
      @container.reload
      expect(@container.status).to eq 'active'
=end


    end

    it 'error in provision' do
      skip("will be later")

      allow(Gexcore::Containers::Provision).to receive(:run_script).and_return(Gexcore::Response.res_error("test_error", "err"))
    end

  end



end
