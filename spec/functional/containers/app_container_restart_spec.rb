RSpec.describe "Restart app container", :type => :request do

  before :each do
    stub_create_node_all

    # app
    @app, @node, @cluster, @user = create_app_active


    @container = @app.containers[0]
  end

  describe 'restart container' do
    before :each do
      #

    end

    it 'DB' do
      # pre check
      expect(@container.status).to eq 'active'

      # work
      cmd = 'restart'
      res = Gexcore::Containers::Control.do_action(@container, cmd)


      # check
      expect(res.success?).to eq true

      @container.reload
      expect(@container.status).to eq 'restarting'
    end

    it 'send command to node' do
      # check
      expect(Gexcore::Nodes::Control).to receive(:rabbitmq_add_command_to_queue).with(@container.node, 'restartContainer', anything).and_return(true)

      # work
      cmd = 'restart'
      res = Gexcore::Containers::Control.do_action(@container, cmd)


    end

    it 'command to node - params' do
      # check
      good_params = [:containerID, :containerName, :containerBasename, :applicationID]
      expect(Gexcore::Nodes::Control).to receive(:rabbitmq_add_command_to_queue).with(@container.node, 'restartContainer', anything) do |node, action, p|
        # params
        good_params.each do |p_name|
          expect(p[p_name]).not_to be_nil
        end

      end.and_return(true)

      # work
      cmd = 'restart'
      res = Gexcore::Containers::Control.do_action(@container, cmd)


    end


    describe 'notify from node' do
      before :each do
        # start restart
        @cmd = 'restart'
        Gexcore::Containers::Control.do_action(@container, @cmd)

      end


      it 'notify from node' do
        # precheck
        expect(@container.status).to eq 'restarting'

        # work
        Gexcore::Containers::Notification.notify('restarted', {'containerID'=>@container.uid})

        # check
        @container.reload

        expect(@container.status).to eq 'active'



      end


    end


  end


end
