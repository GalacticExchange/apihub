RSpec.describe "Verify user", :type => :request do

  before :each do
    @lib = Gexcore::UsersCreationService
    @resp = Gexcore::Response

    stub_create_user_all
  end

  describe 'verify user' do

    it 'email' do
      stub_create_cluster_all

      #
      email = @user_hash[:email]

      #
      message_delivery = instance_double(ActionMailer::MessageDelivery)
      expect(UsersMailer).to receive(:welcome_email).with(email).and_return(message_delivery)
      expect(message_delivery).to receive(:deliver_later)


      # work
      res = @lib.verify_user @token
    end


    it 'error creating cluster' do
      expect(Gexcore::Clusters::Service).to receive(:create_cluster).and_return(@resp.res_error('', 'error'))

      # work
      res = @lib.verify_user @token

      #
      user = User.get_by_username @username

      # check: row in DB
      expect(user.status).to eq User::STATUS_NOT_VERIFIED


    end

    it 'error verify in DB' do
      # TODO: do it
      raise 'will be later'
    end

  end
end



describe 'create_user_not_verified - enterprise' do
    before :each do
      @user_hash = build_user_hash

      @user = @lib.build_user_from_params @user_hash

      @sysinfo = build_sysinfo

      @is_enterprise = true
      @enterprise_options = build_user_options_enterprise

    end


    describe 'success' do

      it "result" do
        # work
        res = @lib.create_user_not_verified(@user, @sysinfo, @is_enterprise, @enterprise_options)


        # check
        expect(res.success?).to be true

        #
        token = res.sysdata[:token]

        # row in DB
        row = User.get_by_username @user_hash[:username]

        expect(row.status).to eq User::STATUS_NOT_VERIFIED
        expect(row.confirmation_token).not_to be_empty
        expect(row.confirmed_at).to be_falsey

        # user.options
        expect(row.registration_options).not_to be_falsey

        @enterprise_options.each do |s, v|
          opt_name = s.to_s
          next if opt_name=='enterprise'

          expect(row.registration_options_hash[opt_name].to_s).to eq v.to_s
        end



        # team row in DB
        team = Team.get_by_name @user_hash[:teamname]

        expect(team.status).to eq Team::STATUS_NOT_VERIFIED
        expect(team.is_enterprise).to eq true
        #expect(team.name).to eq @teamname


      end

      it 'send email' do
        #
        message_delivery = instance_double(ActionMailer::MessageDelivery)
        expect(UsersMailer).to receive(:verification_email).with(@user_hash[:email], anything).and_return(message_delivery)
        expect(message_delivery).to receive(:deliver_later)


        #
        @res = @lib.create_user_not_verified(@user, @sysinfo, @is_enterprise, @options)
      end
    end

end

describe "create_user_active - Enterprise" do

    before :each do
      @user_hash = build_user_hash

      @sysinfo = build_sysinfo

      #
      @is_enterprise = true
      @options = build_user_options_enterprise

      @user = @lib.build_user_from_params @user_hash
    end


    describe 'success' do
      before :each do


      end

      it "result" do
        # work
        res = @lib.create_user_active(@user, @sysinfo, @is_enterprise, @options)

        # check
        expect(res.success?).to be true

      end

      it 'add row to table users' do
        expect{
          res = @lib.create_user_active(@user, @sysinfo, @is_enterprise, @options)
        }.to change{User.count}.by(1)

      end

      it 'add row to table teams' do
        expect{
          res = @lib.create_user_active(@user, @sysinfo, @is_enterprise, @options)
        }.to change{Team.count}.by(1)

      end

      it 'data in DB' do
        # work
        res = @lib.create_user_active(@user, @sysinfo, @is_enterprise, @options)

        #
        team = Team.get_by_name @user_hash[:teamname]
        user = User.get_by_username @user_hash[:username]

        # user
        expect(user.username).to eq @user_hash[:username]
        expect(user.email).to eq @user_hash[:email]
        expect(user.team_id).to eq team.id
        expect(user.group_id).to eq Group.group_superadmin.id
        expect(user.created_at).to be_truthy

        # options
        expect(user.registration_options).to be_truthy
        @options.each do |s, v|
          opt_name = s.to_s
          next if opt_name=='enterprise'

          expect(user.registration_options_hash[opt_name].to_s).to eq v.to_s
        end


        # user fields
        f = @user_hash[:fields]
        expect(user.firstname).to eq f[:firstname]
        expect(user.lastname).to eq f[:lastname]

        # team
        expect(team.name).to eq @user_hash[:teamname]
        expect(team.uid.length).to be > 2
        expect(team.primary_admin_user_id).to eq user.id
        expect(team.is_enterprise).to eq true

      end

    end
  end

describe 'verify user - enterprise' do

    before :each do
      @user_hash = build_user_hash

      @teamname = @user_hash[:teamname]
      @username = @user_hash[:username]
      @email = @user_hash[:email]
      @pwd = @user_hash[:pwd]

      @sysinfo = build_sysinfo

      @is_enterprise = true
      @enterprise_options = build_user_options_enterprise

      #
      @user = @lib.build_user_from_params @user_hash

      #
      @res_create_user = @lib.create_user_not_verified(@user, @sysinfo, @is_enterprise, @enterprise_options)

      @user = User.get_by_username @user_hash[:username]

      # get token from email or from response
      #@token = @user.confirmation_token
      @token = @res_create_user.sysdata[:token]

      #
      @now = Time.now.utc
      Timecop.freeze(@now)

    end

    after :each do
      Timecop.return
    end


    it "ok - response" do
      # stub
      stub_create_cluster_all

      # work
      res = @lib.verify_user @token


      # response
      expect(res.success?).to be true

      # cluster
      res_cluster = res.data[:cluster]
      expect(res_cluster[:id]).to be_truthy

      # team
      res_team = res.data[:cluster][:team]
      expect(res_team[:id].length).to be > 2

    end


    it "data in DB" do
      # stub
      stub_create_cluster_all

      # work
      res = @lib.verify_user @token

      #
      user = User.get_by_username @user_hash[:username]
      cluster = Cluster.get_by_uid res.data[:cluster][:id]
      team = Team.get_by_name @user_hash[:teamname]


      # check: rows in DB

      # cluster
      expect(cluster.team_id).to eq team.id
      expect(cluster.primary_admin_user_id).to eq user.id

      expect(cluster.name).to eq cluster.domainname
      expect(cluster.name.length).to be > 1

      expect(cluster.domainname.length).to be > 2
      expect(cluster.uid.length).to be > 4

      expect(cluster.is_public).to eq true

      # options
      expect(cluster.options_hash).not_to be_falsey

      @enterprise_options.each do |s, v|
        opt_name = s.to_s
        next if opt_name=='enterprise'

        expect(cluster.options_hash[opt_name].to_s).to eq v.to_s
      end


      # user
      expect(user.status).to eq User::STATUS_ACTIVE
      #expect(row.verification_token).not_to be_empty
      expect((user.confirmed_at - @now)/60).to be < 2
      expect(user.main_cluster_id).to eq cluster.id

      # team
      expect(team.main_cluster_id).to eq cluster.id
      expect(team.is_enterprise).to eq true

    end



    it 'call create_cluster' do
      stub_create_cluster_all

      #
      expect(Gexcore::Clusters::Service).to receive(:create_cluster).and_call_original

      #
      res = @lib.verify_user @token
    end


  end

