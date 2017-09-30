RSpec.describe "Users & passwords", :type => :request do
  before :each do

  end


  describe 'user resetpwdlink' do

    before :each do
      #
      @admin_hash = build_user_hash
      @admin = create_user_active @admin_hash
    end

    after :each do

    end


    it "ok" do
      # prepare
      user_hash = build_user_hash
      victim = create_user_active_in_team(@admin.team_id, user_hash)

      # work
      post_json '/users/password/resetlink', {"username" => user_hash[:username]}, {}

      #
      victim = User.get_by_username(user_hash[:username])

      expect(victim.reset_password_token).not_to be nil

    end

    it 'send email' do
      # prepare
      user_hash = build_user_hash
      create_user_active_in_team(@admin.team_id, user_hash)
      victim = User.get_by_username(user_hash[:username])

      #
      message_delivery = instance_double(ActionMailer::MessageDelivery)
      #expect(UsersMailer).to receive(:resetpassword_email).with(victim.id).and_return(message_delivery)
      expect(UsersMailer).to receive(:resetpassword_email).and_return(message_delivery)
      expect(message_delivery).to receive(:deliver_later)

      #
      post_json '/users/password/resetlink', {"username" => user_hash[:username]}, {}
    end

  end


  describe 'reset password with token' do

    before :each do
      #
      @user_hash = build_user_hash
      @user = create_user_active @user_hash
      @username = @user_hash[:username]


      # send link
      post_json '/users/password/resetlink', {username: @username}, {}

      #
      @user = User.get_by_username(@user_hash[:username])

      #

      @oldpwd = @user_hash[:password]

      # get token from email
      mail = get_last_email @user_hash[:email]

      # token in email
      @reset_password_token = mail_get_resetpwd_token_from_email(mail)

      #@reset_password_token = @user.reset_password_token

    end

    after :each do

    end


    it "ok" do
      # reset with token
      newpwd = generate_pwd
      put_json '/users/password', {passwordToken: @reset_password_token, newPassword: newpwd}

      # check
      resp = last_response

      expect(resp.status).to eq 200

      #
      user = User.get_by_username @username

      # cannot login with old pwd
      token = auth_user(@username, @oldpwd)
      expect(token).to be nil

      # can login with new pwd
      token = auth_user(@username, newpwd)
      expect(token.length).to be > 1



    end
  end
end
