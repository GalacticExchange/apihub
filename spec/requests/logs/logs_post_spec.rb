RSpec.describe "log", :type => :request do

  before :each do
    #
    stub_create_cluster_all

    #
    @log_last_type_id = LogType.order("id desc").first.id
    @log_last_id = LogDebug.order("id desc").first.id
    #@log_system_last_id = LogSystem.order("id desc").first.id
  end

  after :each do
    # delete new logs
    LogType.where("id > ?", @log_last_type_id).delete_all
    LogDebug.where("id > ?", @log_last_id).delete_all
    #LogSystem.where("id > ?", @log_system_last_id).delete_all
  end

  describe "POST /log" do

    before :each do
      @user, @cluster = create_user_and_cluster_onprem

      # auth
      @token = auth_token @user

    end


    after :each do
    end


    describe 'Post with token' do

      it 'post with token' do
        n_old = LogDebug.count
        last_id = LogDebug.order("id desc").first.id

        #
        msg = 'something bad occurred'
        level = 'error'
        log_type = 'error_general'

        data = {
            message: msg, type: log_type,
            version: '0.0.1', level: level,
            teamID: @user.team.uid,
            clusterID: @cluster.uid,
            data: {'hello'=>'me', 'world'=>'you'}
        }

        # work
        post_json '/log', data, {token: @token}

        #
        resp = last_response
        resp_data= JSON.parse(resp.body)

        # expectation
        expect(resp.status).to eq 200

        # DB
        expect(LogDebug.count).to be > n_old

        # data in DB
        row_type = LogType.get_by_name(log_type)

        row = LogDebug.where("id > ?", last_id).where(type_id: row_type.id, team_id: @user.team_id, cluster_id: @cluster.id).first

        expect(row.level).to eq Gexcore::GexLogger.level_number(level)
        expect(row.message).to eq msg
      end


      it 'source' do
        n_old = LogDebug.count
        last_id = LogDebug.order("id desc").first.id

        log_type = 'test_err_'+Gexcore::Common.random_string_digits(20)

        source = 'app'

        #
        data = {
            source: source,
            message: 'something bad occurred',
            type: log_type,
            level: 'error',
            version: '0.0.1',
            username: @user.username,
            #teamID: @user.team.uid,
            #clusterID: @cluster.uid,
            data: {'hello'=>'me', 'world'=>'you'}
        }

        resp_data = post_log(data, @token)

        # check
        expect(LogDebug.count).to be > n_old

        # data in DB
        row_type = LogType.get_by_name(log_type)

        row = LogDebug.where("id > ?", last_id).where(type_id: row_type.id).first

        #
        expect(row.source.name).to eq source

      end


      it 'source=user_action' do
        n_old = LogDebug.count
        last_id = LogDebug.order("id desc").first.id

        # log data
        log_type = 'test_err_'+Gexcore::Common.random_string_digits(20)
        source = 'user_action'

        data = log_data(
            {
                source: source,
                type: log_type,
                username: @user.username,
            })

        resp_data = post_log(data, @token)

        # check
        expect(LogDebug.count).to be > n_old

        # data in DB
        row_type = LogType.get_by_name(log_type)

        row = LogDebug.where("id > ?", last_id).where(type_id: row_type.id).first

        #
        expect(row.source.name).to eq source
        expect(row.user_id).to eq @user.id
      end

      it 'data["data"] = string. post with token' do
        n_old = LogDebug.count
        last_id = LogDebug.order("id desc").first.id

        #
        msg = 'something bad occurred'
        level = 'error'
        log_type = 'error_general'

        data = {
            message: msg, type: log_type,
            version: '0.0.1', level: level,
            teamID: @user.team.uid,
            clusterID: @cluster.uid,
            data: "this is a test string for data"
        }

        # work
        post_json '/log', data, {token: @token}

        #
        resp = last_response
        resp_data= JSON.parse(resp.body)

        # expectation
        expect(resp.status).to eq 200

        # DB
        expect(LogDebug.count).to be > n_old

        # data in DB
        row_type = LogType.get_by_name(log_type)

        row = LogDebug.where("id > ?", last_id).where(type_id: row_type.id, team_id: @user.team_id, cluster_id: @cluster.id).first

        expect(row.level).to eq Gexcore::GexLogger.level_number(level)
        expect(row.message).to eq msg
      end
    end


    describe 'Post without token, with team_uid' do

      describe 'success' do

        it "ok - response" do

          n_old = LogDebug.count
          last_id = LogDebug.order("id desc").first.id

          user = create_user_active_and_create_cluster

          #
          msg = 'something bad occurred'
          level = 'error'
          log_type = 'error_general'

          data = {
              message: msg, type: log_type,
              version: '0.0.1', level: level,
              teamID: user.team.uid,
              clusterID: user.home_cluster.uid,
              data: {'hello'=>'me', 'world'=>'you'}
          }

          # work
          post_json '/log', data

          #
          resp = last_response
          resp_data= JSON.parse(resp.body)

          # expectation
          expect(resp.status).to eq 200

          # DB
          expect(LogDebug.count).to be > n_old

          # data in DB
          row_type = LogType.get_by_name(log_type)

          row = LogDebug.where("id > ?", last_id).where(type_id: row_type.id, team_id: user.team_id, cluster_id: user.home_cluster.id).first

          expect(row.level).to eq Gexcore::GexLogger.level_number(level)
          expect(row.message).to eq msg

        end
    end


    end


    describe 'Post by NodeAgent' do
      before :each do
        @user_hash = build_user_hash
        @user = create_user_active_and_create_cluster(@user_hash)
        @cluster = @user.home_cluster

        # node
        stub_create_node_all

        # install node
        @node = create_node(@cluster)

        #
        #sysinfo = build_sysinfo
        #res = Gexcore::Nodes::Service.create_node(@cluster, sysinfo)
        #@node = Node.get_by_uid res.data[:nodeID]

        # node agent
        @agent_token = @node.agent_token

      end

      it 'ok' do
        n_old = LogDebug.count
        last_id = LogDebug.order("id desc").first.id

        #
        msg = 'something bad occurred 456'
        level = 'error'
        log_type = 'error_general'

        data = {
            message: msg, type: log_type,
            version: '0.0.1', level: level,
            nodeID: @node.uid,
            data: {'hello'=>'me', 'world'=>'you'}
        }

        # work
        post_json '/log', data, {nodeAgentToken: @agent_token}

        #
        resp = last_response
        resp_data= JSON.parse(resp.body)

        # expectation
        expect(resp.status).to eq 200

        # DB
        expect(LogDebug.count).to be > n_old

        # data in DB
        row_type = LogType.get_by_name(log_type)

        row = LogDebug.where("id > ?", last_id).where(type_id: row_type.id, node_id: @node.id).first

        expect(row.level).to eq Gexcore::GexLogger.level_number(level)
        expect(row.message).to eq msg
      end
    end
  end
end
