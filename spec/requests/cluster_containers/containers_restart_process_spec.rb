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


  describe 'Process restart master container' do
    before :each do
      # master container
      @container = @cluster.get_master_container 'hadoop'


    end

    it 'OK' do
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

      # run provision
      allow(Gexcore::Containers::Provision).to receive(:run_script).and_return(Gexcore::Response.res_data)

      Gexcore::Containers::Provision.run_control_command(@container.id, @cmd)

      # status
      @container.reload
      expect(@container.status).to eq 'active'


=begin
      # status
      @container.reload
      expect(@container.status).to eq 'restarting'

      # notify from provision script
      post_json '/notify', {event: 'container_restarted', containerID: @container.uid}, {token: @token}

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
      expect(@container.status).to eq 'restarting'

      # run provision
      allow(Gexcore::Containers::Provision).to receive(:run_script).and_return(Gexcore::Response.res_error("test_error", "err"))

      Gexcore::Containers::Provision.run_control_command(@container.id, @cmd)

      # check
      @container.reload
      expect(@container.status).to eq 'restart_error'


      # v2 - with notify
=begin
      # status
      @container.reload
      expect(@container.status).to eq 'restarting'


      # notify from provision script
      post_json '/notify', {event: 'container_restart_error', containerID: @container.uid}, {token: @token}

      # check
      @container.reload
      expect(@container.status).to eq 'restart_error'
=end


    end
  end




  describe 'Process restart slave container' do

    before :each do
      # active node
      stub_create_node_all

      @node = create_node_active(@cluster)

      # container
      stub_container_provision_all

      @container = Gexcore::Containers::Service.get_slave_by_basename(@node, 'hadoop')

    end


    it 'OK' do
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

      # run provision
      allow(Gexcore::Containers::Provision).to receive(:run_script).and_return(Gexcore::Response.res_data)

      Gexcore::Containers::Provision.run_control_command(@container.id, @cmd)

      # check
      @container.reload
      expect(@container.status).to eq 'active'


=begin
      # status
      @container.reload
      expect(@container.status).to eq 'restarting'


      # notify from provision script
      post_json '/notify', {event: 'container_restarted', containerID: @container.uid}, {token: @token}

      # check
      @container.reload
      expect(@container.status).to eq 'active'
=end

    end

    it 'error in provision' do
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

      # run provision
      allow(Gexcore::Containers::Provision).to receive(:run_script).and_return(Gexcore::Response.res_error("test_error", "err"))

      Gexcore::Containers::Provision.run_control_command(@container.id, @cmd)

      # check
      @container.reload
      expect(@container.status).to eq 'restart_error'


=begin
      # status
      @container.reload
      expect(@container.status).to eq 'restarting'


      # notify from provision script
      post_json '/notify', {event: 'container_restart_error', containerID: @container.uid}, {token: @token}

      # check
      @container.reload
      expect(@container.status).to eq 'restart_error'
=end

    end

  end



end
