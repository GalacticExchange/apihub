RSpec.describe "user creation", :type => :request do

  before :each do
    @lib = Gexcore::UsersCreationService
    @clsResp = Gexcore::Response

    @sysinfo = build_sysinfo

  end


  describe 'create user with test phone' do

    describe 'success path' do

      before :each do
        clear_all_emails

        #
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
        expect(@user_hash[:phone_number]).to eq Gexcore::Settings.TEST_PHONE_NUMBER
        expect(@user_hash[:password]).to eq Gexcore::Settings.TEST_USER_PWD

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
        expect(user.confirmed_at).not_to be_nil
        expect(user.verified?).to eq true

        expect(user.status).to eq User::STATUS_ACTIVE

        User::FIELDS_COMMON.each do |f|
          expect(user[f.to_sym]).to eq @user_hash[f.to_sym]
        end

        # team
        expect(team.name).to eq @teamname
        expect(team.uid.length).to be > 2
        expect(team.primary_admin_user_id).to eq user.id

      end


      it 'send welcome email' do
        #
        message_delivery = instance_double(ActionMailer::MessageDelivery)
        expect(UsersMailer).to receive(:phone_verification_email).and_return(message_delivery)
        expect(message_delivery).to receive(:deliver_later)

        #
        post_json '/users', @user_post, {}


      end

      it 'phone_verification_email email' do
        #
        post_json '/users', @user_post, {}


        # email content
        mail = get_last_email @user_post[:email]
        html = mail['parts'][0]['body']

        expect(html).to match /#{@user_hash[:firstname]}/im
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
        raise 'deprecated'

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
        raise 'deprecated'

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


  describe 'create user with Good phone' do
    before :each do
      clear_all_emails

      #
      @user_hash = build_user_hash({phone_number: generate_phone})

      #
      @user_post = build_user_create_post(@user_hash)

    end

    after :each do

    end


    it "ok - response" do
      # prepare
      expect(@user_hash[:phone_number]).not_to eq Gexcore::Settings.TEST_PHONE_NUMBER

      # work
      post_json '/users', @user_post, {}

      #
      resp = last_response
      resp_data = response_json

      # expectation
      expect(resp.status).to eq 200
      expect(resp_data).to be_empty

    end


    it "user status" do
      # work
      post_json '/users', @user_post, {}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)


      # check
      user = User.get_by_username @user_hash[:username]
      team = Team.get_by_name @user_hash[:teamname]

      # user
      expect(user.status).to eq User::STATUS_ACTIVE

    end



    it 'send Welcome email' do
      #
      message_delivery = instance_double(ActionMailer::MessageDelivery)
      expect(UsersMailer).to receive(:phone_verification_email).and_return(message_delivery)
      expect(message_delivery).to receive(:deliver_later)

      #
      post_json '/users', @user_post, {}


    end
  end

  describe 'create user with BAD phone' do

    before :each do
      clear_all_emails

      @phone_number = generate_phone_bad

      #
      @user_hash = build_user_hash({phone_number: @phone_number})

      #
      @user_post = build_user_create_post(@user_hash)

      # invalidate country for registration
      allow(Gexcore::Settings).to receive(:get_option).with('registration_countries', anything).and_return(['UA'])

    end

    after :each do

    end


    it "ok - response" do
      # prepare
      expect(@user_hash[:phone_number]).not_to eq Gexcore::Settings.TEST_PHONE_NUMBER

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
      user = User.get_by_username @user_hash[:username]
      team = Team.get_by_name @user_hash[:teamname]

      # user
      expect(user.created_at).not_to be_nil

      # verified?
      expect(user.confirmation_token).not_to be_empty
      #expect(user.confirmed_at).to be_nil
      expect(user.verified?).to eq false

      expect(user.status).to eq User::STATUS_NOT_VERIFIED

      User::FIELDS_COMMON.each do |f|
        expect(user[f.to_sym]).to eq @user_hash[f.to_sym]
      end

      # team
      expect(team.name).to eq @user_hash[:teamname]
      expect(team.uid.length).to be > 2
      expect(team.primary_admin_user_id).to eq user.id

    end



    it 'send registration_email' do
      # send welcome email
      message_delivery = instance_double(ActionMailer::MessageDelivery)
      expect(UsersMailer).to receive(:registration_email).with(@user_hash[:email]).and_return(message_delivery)
      expect(message_delivery).to receive(:deliver_later)

      # work
      post_json '/users', @user_post, {}

    end

  end

end
