RSpec.describe "Create user", :type => :request do

  before :each do
    @lib = Gexcore::UsersCreationService
    @resp = Gexcore::Response

    stub_create_user_all
  end


  describe 'create_user_not_verified' do
    before :each do
      @user_hash = build_user_hash

      @user = @lib.build_user_from_params @user_hash

      @sysinfo = build_sysinfo

    end


    describe 'success' do

      it "result" do
        # work
        res = @lib.create_user_not_verified(@user, @sysinfo)


        # check
        expect(res.success?).to be true

        #
        token = res.sysdata[:token]

        # row in DB
        row = User.get_by_username @user_hash[:username]

        expect(row.status).to eq User::STATUS_NOT_VERIFIED
        expect(row.confirmation_token).not_to be_empty
        expect(row.confirmed_at).to be_falsey

        # team row in DB
        team = Team.get_by_name @user_hash[:teamname]

        expect(team.status).to eq Team::STATUS_NOT_VERIFIED
        #expect(team.name).to eq @teamname


      end

      it 'send email' do
        #
        message_delivery = instance_double(ActionMailer::MessageDelivery)
        expect(UsersMailer).to receive(:verification_email).with(@user_hash[:email], anything).and_return(message_delivery)
        expect(message_delivery).to receive(:deliver_later)


        #
        @res = @lib.create_user_not_verified(@user, @sysinfo)
      end
    end




    describe 'errors' do

      it 'error. team exists' do
        # create one user
        res_user = @lib.create_user_active(@user, @sysinfo)


        # try to add with the same teamname
        n_old = Team.count

        user2_hash = @user_hash.clone
        user2_hash[:username] = generate_username
        user2_hash[:email] = generate_email
        user2 = @lib.build_user_from_params user2_hash

        #
        res = @lib.create_user_not_verified(user2, @sysinfo)

        #
        expect(res.success?).to be_falsey
        expect(Team.count).to eq n_old

        # error
        #expect(res.error_name_small).to eq 'user_create_team_name_used'
      end



    end

  end




  describe "create_user_active" do

    before :each do
      @user_hash = build_user_hash

      @sysinfo = build_sysinfo

      @user = @lib.build_user_from_params @user_hash
    end


    describe 'success' do
      before :each do


      end

      it "result" do
        # work
        res = @lib.create_user_active(@user, @sysinfo)

        # check
        expect(res.success?).to be true

      end

      it 'add row to table users' do
        expect{
          res = @lib.create_user_active(@user, @sysinfo)
        }.to change{User.count}.by(1)

      end

      it 'add row to table teams' do
        expect{
          res = @lib.create_user_active(@user, @sysinfo)
        }.to change{Team.count}.by(1)

        team = Team.get_by_name @user_hash[:teamname]
        expect(team.name).to eq @user_hash[:teamname]

      end

      it 'data in DB' do
        # work
        res = @lib.create_user_active(@user, @sysinfo)

        #
        team = Team.get_by_name @user_hash[:teamname]
        user = User.get_by_username @user_hash[:username]

        # user
        expect(user.username).to eq @user_hash[:username]
        expect(user.email).to eq @user_hash[:email]
        expect(user.team_id).to eq team.id
        expect(user.group_id).to eq Group.group_superadmin.id
        expect(user.created_at).to be_truthy

        # user fields
        f = @user_hash[:fields]
        expect(user.firstname).to eq f[:firstname]
        expect(user.lastname).to eq f[:lastname]

        # team
        expect(team.name).to eq @user_hash[:teamname]
        expect(team.uid.length).to be > 2
        expect(team.primary_admin_user_id).to eq user.id

      end

    end

    describe 'errors' do

      it 'email used' do
        #
        res_user = @lib.create_user_active(@user, @sysinfo)


        # try to add with the same email
        n_old = User.count

        #
        user_hash2 = @user_hash.clone
        user_hash2[:username] = user_hash2[:username]+'new'
        user_hash2[:password] = user_hash2[:password]+'111'
        user2 = @lib.build_user_from_params user_hash2

        res = @lib.create_user_active(user2, @sysinfo)

        #
        expect(res.success?).to be_falsey
        expect(User.count).to eq n_old

        # error
        #expect(res.error_name_small).to eq 'user_create_email_used'

      end

      it 'username used' do
        #
        res_user = @lib.create_user_active(@user, @sysinfo)


        # try to add with the same email
        n_old = User.count

        # user2
        user_hash2 = @user_hash.clone
        user_hash2[:email] = 'new'+user_hash2[:email]
        user_hash2[:password] = user_hash2[:password]+'111'
        user2 = @lib.build_user_from_params user_hash2

        res = @lib.create_user_active(user2, @sysinfo)

        #
        expect(res.success?).to be_falsey
        expect(User.count).to eq n_old

        # error
        #expect(res.error_name_small).to eq 'user_create_username_used'

      end



    end


    describe 'transaction' do

=begin
      it 'fail to add openam' do

        # prepare
        count_old = User.count
        team_count_old = Team.count

        # stub openam request
        allow_any_instance_of(Apiservice::OpenamRequest)
            .to receive(:create_user)
                    .and_return(Apiservice::Response.res_error("", "unk error"))

        # work
        @res = Apiservice::UsersCreationLib.create_user(@teamname, @username, @email, @pwd, @user_fields, @sysinfo)

        # check

        # user should not be created in DB
        user_new = User.get_by_username @username
        expect(user_new).to be_falsey
        expect(User.count).to eq count_old
        expect(Team.count).to eq team_count_old


      end
=end

=begin
      it 'fail add to db' do

        # prepare
        count_old = User.count

        # stub add db
        allow_any_instance_of(User).to receive(:save).and_return(false)

        # work
        @res = Apiservice::UsersCreationLib.create_user(@teamname, @username, @email, @pwd, @user_fields, @sysinfo)

        # check

        # user should not be created in OpenAM
        res_openam_user = Apiservice::OpenamService.get_user(@username)

        #
        expect(res_openam_user.success?).to eq false

        # user should not be created in DB
        user_new = User.get_by_username @username
        expect(user_new).to be_falsey
        expect(User.count).to eq count_old


      end
=end

    end

    describe 'create user with parameters of deleted user' do
      before :each do
        #
        stub_create_user_all

        # create user with cluster
        @admin = create_user_active


        # add user to team
        @user_hash = build_user_hash
        @user = create_user_active_in_team(@admin.team_id, @user_hash)

        # delete user
        Gexcore::UsersService.delete_user_by_admin(@user.username, @admin)

      end

      it "can use the email/username of the deleted user" do
        # work

        # create user with same email and username
        user2_hash = build_user_hash
        user2_hash[:username] = @user_hash[:username]
        user2_hash[:email] = @user_hash[:email]
        user2 = @lib.build_user_from_params user2_hash

        res = @lib.create_user_active_in_team(user2, @admin.team_id)

        # check
        expect(res.success?).to be true

        # info
        res_info = Gexcore::UsersService.get_user_info(user2.username)

        # check
        expect(res_info.success?).to be true
        expect(res_info.data[:user][:username]).to eq user2_hash[:username]
      end



    end


  end



  describe 'verify user' do

    before :each do
      @user_hash = build_user_hash

      @teamname = @user_hash[:teamname]
      @username = @user_hash[:username]
      @email = @user_hash[:email]
      @pwd = @user_hash[:pwd]

      @sysinfo = build_sysinfo

      #
      @user = @lib.build_user_from_params @user_hash

      #
      @res_create_user = @lib.create_user_not_verified(@user, @sysinfo)

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

    describe 'verify_user' do

      it "ok - response" do
        # work
        res = @lib.verify_user @token


        # response
        expect(res.success?).to be true

        # team
        res_team = res.data[:team]
        expect(res_team[:id].length).to be > 2
        expect(res_team[:name].length).to be > 2

      end


      it "data in DB" do
        # work
        res = @lib.verify_user @token

        #
        user = User.get_by_username @user_hash[:username]
        team = Team.get_by_name @user_hash[:teamname]


        # check: rows in DB

        # user
        expect(user.status).to eq User::STATUS_ACTIVE
        #expect(row.verification_token).not_to be_empty
        expect((user.confirmed_at - @now)/60).to be < 2

        # team
        #expect(team.main_cluster_id).to eq cluster.id

      end


      it 'error verify in DB' do
        skip
        # TODO: do it
        raise 'will be later'
      end

    end

    describe 'verify_user_by_token' do

      it 'email' do
        #
        email = @user_hash[:email]

        #
        message_delivery = instance_double(ActionMailer::MessageDelivery)
        expect(UsersMailer).to receive(:welcome_email).with(email).and_return(message_delivery)
        expect(message_delivery).to receive(:deliver_later)


        # work
        res = @lib.verify_user_by_token @token
      end

    end

  end




end
