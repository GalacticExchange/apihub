RSpec.describe "View log", :type => :request do

  before :all do
    # clean all logs
    LogDebug.delete_all
    LogSystem.delete_all

    #
    prefix = Rails.configuration.gex_config[:elasticsearch_prefix]
    LogDebug.import(:force=>true, index: prefix+'log_debug')
    LogDebug.__elasticsearch__.refresh_index!

    sleep 4

  end

  before :each do
    #
    stub_create_user_all
    stub_create_cluster_all
    stub_create_node_all
    #
    @user_hash = build_user_hash
    @user = create_user_active_and_create_cluster(@user_hash)
    @cluster = @user.home_cluster

    # auth
    @token = auth_user_hash @user_hash

    # random users
    # user in team
    #@user_hash2 = build_user_hash
    #@user2 = create_user_active_in_team(@user.team_id, @user_hash2)
    #@cluster2 = @user2.home_cluster

    # user another team
    #@user_hash3 = build_user_hash
    #@user3 = create_user_active_and_create_cluster(@user_hash3)
    #@cluster3 = @user3.home_cluster

  end


  describe 'GET /logs' do
=begin
    before :each do
      @user_hash = build_user_hash
      @user = create_user_active_and_create_cluster(@user_hash)
      @cluster = @user.home_cluster

      # auth
      @token = auth_user_hash @user_hash

    end


    after :each do
    end
=end
    it 'general' do
      # source=all

      # add with source=user_action
      post_log({source: 'user_action', level: 'info', username: @user.username}, @token)

      # add with source=server, nodeID=XX
      post_log({source: 'server', level: 'info', nodeID: 123}, @token)

      # для того, чтобы база успела проиндексироваться, ставим sleep
      sleep 3

      # get
      get_json '/logs', {level: 'info'}, {token: @token}

      resp = last_response
      resp_data= JSON.parse(resp.body)

      rows = resp_data['result']

      expect(rows.length).to be > 0
      expect(rows[0]['source']).to eq 'server'

    end

    describe 'filter by level' do

      it 'level info' do
        post_log({source: 'user_action', level: 'info', username: @user.username}, @token)
        post_log({source: 'server', level: 'error', nodeID: 126}, @token)
        post_log({source: 'server', level: 'critical', nodeID: 127}, @token)

        #sleep 3

        # get
        get_json '/logs', {minLevel: 'debug'}, {token: @token}

        resp = last_response
        resp_data= JSON.parse(resp.body)
        rows = resp_data['result']

        expect(rows.length).to eq 3

        good_logs = ["info", "critical", "error"]

        rows.each do |log|
          expect(good_logs.include? log["level"]).to be true
        end
      end

      it 'level critical' do
        post_log({source: 'user_action', level: 'critical', username: @user.username}, @token)
        post_log({source: 'user_action', level: 'info'}, @token)

        #sleep 4

        # get
        get_json '/logs', {minLevel: 'critical'}, {token: @token}

        resp = last_response
        resp_data= JSON.parse(resp.body)
        rows = resp_data['result']

        expect(rows.length).to eq 1

        good_logs = ["critical"]

        rows.each do |log|
          expect(good_logs.include? log["level"]).to be true
        end
      end

    end

    describe 'filter by source' do

      it 'filter by source 1' do
        # add log with user_action

        log_type = 'test_err_'+Gexcore::Common.random_string_digits(20)
        #
        data = {
            source: 'user_action',
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

        # add another log
        log_type2 = 'test_err_'+Gexcore::Common.random_string_digits(20)
        #
        data2 = {
            source: 'server',
            message: 'something test',
            type: log_type2,
            level: 'error',
            version: '0.0.1',
            username: @user.username,
            #teamID: @user.team.uid,
            #clusterID: @cluster.uid,
            data: {'hello'=>'me', 'world'=>'you'}
        }
        resp_data2 = post_log(data2, @token)

        #sleep 4

        # get
        get_json '/logs', {source: 'user_action'}, {token: @token}

        resp = last_response
        resp_data= JSON.parse(resp.body)
        rows = resp_data['result']

        expect(rows.length).to eq 1

        good_source = ["user_action"]

        rows.each do |log|
          expect(good_source.include? log["source"]).to be true
        end


      end

      it 'filter by source user_action + user' do
        # stub can? => true
        stub_user_can_true
        # user2
        @user_hash2 = build_user_hash
        @user2 = create_user_active_in_team(@user.team_id, @user_hash2)
        @user2_token = auth_user_hash @user_hash2


        # add log with user_action, username=XX
        log_type = 'test_err_'+Gexcore::Common.random_string_digits(20)
        data = log_data({
            source: 'user_action',
            message: "invitation sent to user2",
            type: log_type,
            level: 'info',
            #username: @user2.username,
        })

        resp_data = post_log(data, @token)

        # log2. with nodeID
        log_type2 = 'test_err_'+Gexcore::Common.random_string_digits(20)
        data2 = log_data({
            source: 'server',
            message: 'server ',
            type: log_type2,
            level: 'error',
            nodeID: 12,
        })
        resp_data2 = post_log(data2, @token)

        # log3. add another log
        log_type3 = 'test_err_'+Gexcore::Common.random_string_digits(20)
        data3 = log_data({
            source: 'server',
            message: 'something test',
            type: log_type3,
            level: 'error',
        })
        resp_data3 = post_log(data3, @token)


        # get username=XX, source=user_action
        get_json '/logs', {source: 'user_action', username: @user.username}, {token: @user2_token}

        resp = last_response
        resp_data= JSON.parse(resp.body)
        rows = resp_data['result']

        expect(rows.length).to eq 1

        good_source = ["user_action"]
        good_username = [@user.username]

        rows.each do |log|
          expect(good_source.include? log["source"]).to be true
          expect(good_username.include? log["user"]["username"]).to be true
        end
      end
    end


    describe 'filter by user' do
      it 'not-existing username' do

        # filter by not existing username
        log_type = 'test_err_'+Gexcore::Common.random_string_digits(20)
        #
        data = {
            source: 'user_action',
            message: 'something bad occurred',
            type: log_type,
            level: 'error',
            version: '0.0.1',
            data: {'hello'=>'me', 'world'=>'you'}
        }
        resp_data = post_log(data, @token)

        #sleep 4

        # now it is wrong - it returns logs of the current user
        get_json '/logs', {username: "vasiliy"}, {token: @token}

        resp = last_response
        resp_data= JSON.parse(resp.body)
        rows = resp_data['errors']

        expect(rows[0]['message']).to eq 'User does not exist'

      end
    end

    describe 'filter by fields' do
      it 'filter by nodeID' do

        # stub can? => true
        stub_user_can_true
        # user2
        @user_hash2 = build_user_hash
        @user2 = create_user_active_in_team(@user.team_id, @user_hash2)
        @user2_token = auth_user_hash @user_hash2

        # node install
        node = create_node_status_active(@cluster)

        # add log with user_action, username=XX, nodeID=XX
        log_type = 'test_err_'+Gexcore::Common.random_string_digits(20)
        data = log_data({
                            source: 'node',
                            message: "restart node",
                            type: log_type,
                            level: 'info',
                            nodeID: node.uid,
                            #username: @user2.username,
                        })

        resp_data = elvis_post_log(data, @token)

        # node install
        node2 = create_node_status_active(@cluster)

        # add log with source=server, nodeID
        log_type2 = 'test_err_'+Gexcore::Common.random_string_digits(20)
        data2 = log_data({
                             source: 'node',
                             message: 'server ',
                             type: log_type2,
                             level: 'error',
                             nodeID: node2.uid,
                         })
        resp_data2 = elvis_post_log(data2, @token)
        # add another log

        log_type3 = 'test_err_'+Gexcore::Common.random_string_digits(20)
        data3 = log_data({
                             source: 'server',
                             message: 'something test',
                             type: log_type3,
                             level: 'error',
                         })
        resp_data3 = elvis_post_log(data3, @token)

        # get source=all, nodeID=XX
        get_json '/logs', {nodeID: node.uid}, {token: @user2_token}

        resp = last_response
        resp_data= JSON.parse(resp.body)
        rows = resp_data['result']

        expect(rows.length).to eq 2

        good_source = ["node", 'server']
        good_level = ["info"]
        good_node_id = [node.id]

        rows.each do |log|
          expect(good_source.include? log["source"]).to be true
          expect(good_level.include? log["level"]).to be true
          expect(good_node_id.include? log["data"]["node_id"]).to be true
        end

      end

      it 'filter by clusterID' do
        # stub can? => true
        stub_user_can_true
        # user2
        @user_hash2 = build_user_hash
        @user2 = create_user_active_in_team(@user.team_id, @user_hash2)
        @user2_token = auth_user_hash @user_hash2
        # user another team
        @user_hash3 = build_user_hash
        @user3 = create_user_active_and_create_cluster(@user_hash3)
        @user3_token = auth_user_hash @user_hash3

        # add log with user_action, username=XX
        log_type = 'test_err_'+Gexcore::Common.random_string_digits(20)
        data = log_data({
                            source: 'user_action',
                            message: "invitation sent to user2",
                            type: log_type,
                            level: 'info',
                            #username: @user2.username,
                        })

        resp_data = post_log(data, @token)

        # log2. with nodeID
        log_type2 = 'test_err_'+Gexcore::Common.random_string_digits(20)
        data2 = log_data({
                             source: 'server',
                             message: 'server ',
                             type: log_type2,
                             level: 'error',
                             nodeID: 12,
                         })
        resp_data2 = post_log(data2, @token)

        # log3. add another log
        log_type3 = 'test_err_'+Gexcore::Common.random_string_digits(20)
        data3 = log_data({
                             source: 'server',
                             message: 'something test',
                             type: log_type3,
                             level: 'error',
                         })
        resp_data3 = post_log(data3, @user3_token)


        # get username=XX, source=user_action
        get_json '/logs', {clusterID: @cluster.id}, {token: @user2_token}

        resp = last_response
        resp_data= JSON.parse(resp.body)
        rows = resp_data['result']

        expect(rows.length).to eq 2

        good_source = ["user_action", "server"]
        good_username = [@user.username]
        bad_message = ['something test']

        rows.each do |log|
          expect(good_source.include? log["source"]).to be true
          expect(good_username.include? log["user"]["username"]).to be true
          expect(bad_message.include? log["message"]).to be false
        end


      end

      it 'no log if visible_client: 0' do
        # type
        type = 'test_err_'+Gexcore::Common.random_string_digits(20)

        # add with source=user_action
        elvis_invisible_post_log({source: 'user_action', type: type, level: 'info', username: @user.username}, @token)

        # get
        get_json '/logs', {level: 'info'}, {token: @token}

        resp = last_response
        resp_data= JSON.parse(resp.body)

        rows = resp_data['result']

        #
        expect(rows.empty?).to be true

      end

      it 'view log if visible_client: 1' do
        # source=all

        # add with source=user_action
        elvis_post_log({source: 'user_action', type: 'notify_node', level: 'info', username: @user.username}, @token)

        # get
        get_json '/logs', {level: 'info'}, {token: @token}

        resp = last_response
        resp_data= JSON.parse(resp.body)

        rows = resp_data['result']

        #
        expect(rows.length).to be > 0

      end


    end

  end

end
