RSpec.describe "Restart master container", :type => :request do

  before :each do
    @lib = Gexcore::Containers::Control

    # create user with cluster
    stub_create_user_all
    stub_create_cluster_all


    #
    @user, @cluster = create_user_and_cluster_onprem

    # master container
    @container = @cluster.get_master_container 'hadoop'

    @cmd = 'restart'
  end


  describe 'Process restart master container' do
    it 'OK' do
      # work
      res = @lib.restart_container(@container)

      #
      expect(res.success?).to eq true

      # status
      @container.reload
      expect(@container.status).to eq 'restarting'


      # run provision
      allow(Gexcore::Provision::Service).to receive(:run).with('change_master_container_state_restart', anything).and_return(Gexcore::Response.res_data)
      Gexcore::Containers::Provision.run_control_command(@container.id, @cmd)


      # check
      @container.reload
      expect(@container.status).to eq 'active'


    end

    it 'process - error in provision' do
      # work
      res = @lib.restart_container(@container)

      # status
      @container.reload
      expect(@container.status).to eq 'restarting'

      # error in provision
      allow(Gexcore::Provision::Service).to receive(:run).with('change_master_container_state_restart', anything).and_return(Gexcore::Response.res_error("test_error", "err"))

      Gexcore::Containers::Provision.run_control_command(@container.id, @cmd)

      # check
      @container.reload
      expect(@container.status).to eq 'restart_error'

    end
  end


end

