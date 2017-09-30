RSpec.describe "user creation", :type => :request do

  before :each do
    @lib = Gexcore::UsersCreationService
    @clsResp = Gexcore::Response

    @sysinfo = build_sysinfo

  end


  describe 'create user' do

    describe 'success path' do

      before :each do
        @user_hash = build_user_hash

        @teamname = @user_hash[:teamname]
        @username = @user_hash[:username]
        @email = @user_hash[:email]
        @pwd = @user_hash[:pwd]

        #
        @user_post = build_user_create_post(@user_hash)

      end

      after :each do

      end


      it "ok - response" do
        # prepare

        # work
        post_json '/users', @user_post, {}

        #
        resp = last_response
        resp_data = response_json

        # expectation
        expect(resp.status).to eq 200
        expect(resp_data).to be_empty

      end


      it "data in DB" do
        # work
        post_json '/users', @user_post, {}

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)


        # check
        user = User.get_by_username(@username)
        team = Team.get_by_name @teamname

        # user
        expect(user.created_at).not_to be_nil

        # verified?
        expect(user.confirmation_token).not_to be_empty
        expect(user.confirmed_at).to be_nil
        expect(user.verified?).to eq false

        expect(user.status).to eq User::STATUS_NOT_VERIFIED
        #expect(user.group.id).to eq Group.group_superadmin.id

        User::FIELDS_COMMON.each do |f|
          expect(user[f.to_sym]).to eq @user_hash[f.to_sym]
        end

        # team
        expect(team.name).to eq @teamname
        expect(team.uid.length).to be > 2
        expect(team.primary_admin_user_id).to eq user.id

      end


      it 'send email' do
        #
        message_delivery = instance_double(ActionMailer::MessageDelivery)
        expect(UsersMailer).to receive(:verification_email).and_return(message_delivery)
        expect(message_delivery).to receive(:deliver_later)

        #
        post_json '/users', @user_post, {}


      end

      it 'verification email' do
        #
        post_json '/users', @user_post, {}


        # email content
        mail = get_last_email @user_post[:email]
        token = api_mail_get_verification_token_from_email(mail)

        expect(token.length).to be > 0
      end

    end


    describe 'errors' do

      it 'teamname exist' do
        # prepare
        user1 = create_user_active

        # try to create with the same team
        user2_hash = build_user_hash
        user2_hash[:teamname] = user1.team.name
        user2_post = build_user_create_post user2_hash


        #
        n_old = Team.count

        post_json '/users', user2_post, {}

        #
        expect(Team.count).to eq n_old

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        expect(resp.status).to eq(400)
        #expect(resp_errorname(resp_data)).to eq 'user_create_team_name_used'


      end

      it 'error - username used' do
        # prepare
        user1 = create_user_active

        # try to create with the same email
        user2_hash = build_user_hash
        user2_hash[:username] = user1.username
        user2_post = build_user_create_post user2_hash


        #
        n_old = User.count

        post_json '/users', user2_post, {}

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        expect(resp.status).to eq(400)
        #expect(resp_errorname(resp_data)).to eq 'user_create_username_used'
        expect(User.count).to eq n_old

      end

      it 'bad password length' do
        # try to create with the same email
        user_hash = build_user_hash
        user_post = build_user_create_post user_hash
        user_post[:password] = '1'


        #
        n_old = User.count

        post_json '/users', user_post, {}

        #
        expect(User.count).to eq n_old

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        #
        expect(resp.status).to eq(400)

      end

      it 'blank password' do
        # try to create with the same email
        user_hash = build_user_hash
        user_post = build_user_create_post user_hash
        user_post.delete(:password)


        #
        n_old = User.count

        post_json '/users', user_post, {}

        #
        expect(User.count).to eq n_old

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        #
        expect(resp.status).to eq(400)
      end

    end
  end


  describe 'user verify' do

    before :each do
      clear_all_emails

      #
      @user_hash = build_user_hash

      @user = @lib.build_user_from_params @user_hash

      #
      @lib.create_user_not_verified(@user, @sysinfo)

      #
      @username = @user.username
      @user = User.get_by_username @username


      # get token from email
      mail = get_last_email @user_hash[:email]
      @token = api_mail_get_verification_token_from_email(mail)

    end

    describe 'success path' do
      before :each do
        @verify_post = {'verificationToken'=> @token}


      end

      it 'response' do
        # work
        post_json '/users/verify', @verify_post

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        expect(resp.status).to eq 200

        # response

        # team
        res_team = resp_data['team']
        expect(res_team['id'].length).to be > 2
        expect(res_team['name'].length).to be > 2


      end


      it 'user active' do
        # work
        post_json '/users/verify', @verify_post, {}

        #
        user = User.get_by_username @username

        # check: row in DB
        expect(user.active?).to eq true
      end


      it 'team active' do
        # work
        post_json '/users/verify', @verify_post, {}

        #
        user = User.get_by_username @username
        team = user.team

        # check: row in DB
        expect(team.active?).to eq true
      end


      it 'send Welcome email' do
        # send welcome email
        message_delivery = instance_double(ActionMailer::MessageDelivery)
        expect(UsersMailer).to receive(:welcome_email).with(@user_hash[:email]).and_return(message_delivery)
        expect(message_delivery).to receive(:deliver_later)

        # do not send email with cluster
        message_delivery = instance_double(ActionMailer::MessageDelivery)
        expect(UsersMailer).not_to receive(:cluster_info_email)


        # work
        post_json '/users/verify', @verify_post, {}

      end


    end


    describe 'verify - transaction' do

      before :each do
        @verify_post = {'verificationToken'=>Gexcore::TokenGenerator.generate_verification_token}

      end

      it 'cannot create cluster' do
        allow(Gexcore::Clusters::Service).to receive(:create_cluster).and_return(@clsResp.res_error('','err'))

        # work
        post_json '/users/verify', @verify_post, {}

        # check: not verified
        expect(@user.active?).to eq false

      end
    end

    describe 'verify - errors' do

      it 'non exist token' do
        new_token = Gexcore::TokenGenerator.generate_verification_token
        postdata = {'verificationToken'=>new_token}

        # work
        post_json '/users/verify', postdata, {}

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        #
        expect(resp.status).to eq 403
      end

      it 'token used' do
        postdata = {'verificationToken'=>@token}

        # work
        post_json '/users/verify', postdata, {}

        # verify again
        post_json '/users/verify', postdata, {}

        resp = last_response
        resp_data = JSON.parse(resp.body)

        #
        expect(resp.status).to eq 403
      end
    end



  end


end
