RSpec.describe "Users & password", :type => :request do
  before :each do

  end

  describe 'user change password with old password' do

    before :each do
      @admin_hash = build_user_hash
      @admin = create_user_active @admin_hash


    end

    after :each do

    end


    it "change own password with old+new password" do
      # auth main user
      @token = auth_user_hash(@admin_hash)

      # work
      newpwd = 'Galactic2'
      put_json '/users/password', {"oldPassword" => @admin_hash[:password], "newPassword" => newpwd}, {"token" => @token}

      #
      @admin.reload

      # check
      user_hash = @admin_hash.clone

      # cannot login with old pwd
      token_old = auth_user_hash(@admin_hash)
      expect(token_old).to be nil

      # can login with new pwd
      user_hash[:password] = newpwd
      token_new = auth_user_hash(user_hash)
      expect(token_new.length).to be > 1


    end

    it 'do not change if old password is invalid' do
      # auth main user
      @token = auth_user_hash(@admin_hash)

      # work
      oldpwd = @admin_hash[:password]
      pwd_bad = generate_pwd
      newpwd = generate_pwd

      #
      put '/users/password', {"oldPassword" => pwd_bad, "newPassword" => newpwd}, {"token" => @token}

      #
      resp = last_response
      data = response_json

      #
      expect(resp.status).not_to eq 200

      #
      @admin.reload

      # check
      username = @admin_hash[:username]

      # still can login with old pwd
      token = auth_user(username, oldpwd)
      expect(token.length).to be > 1

      # cannot login with new pwd
      token = auth_user(username, newpwd)
      expect(token).to be nil

    end



  end

  describe 'admin change password for another user' do
    before :each do
      @admin_hash = build_user_hash
      @admin = create_user_active @admin_hash

    end


    it "admin change password for another user" do
      # prepare

      # new user in our team
      user_hash = build_user_hash
      victim = create_user_active_in_team(@admin.team_id, user_hash)

      oldpwd = user_hash[:password]
      newpwd = generate_pwd

      # auth admin
      @token = auth_user_hash(@admin_hash)

      # work
      put '/users/password', {"username" => user_hash[:username], "newPassword" => newpwd}, {"token" => @token}

      #
      resp = last_response

      expect(resp.status).to eq 200


      #
      user = User.get_by_username user_hash[:username]

      # cannot login with old pwd
      token = auth_user(user_hash[:username], oldpwd)
      expect(token).to be nil

      # can login with new pwd
      token = auth_user(user_hash[:username], newpwd)
      expect(token.length).to be > 1

    end

    it 'admin can change user only from his team' do
      # another user in another team
      user_hash = build_user_hash
      user = create_user_active user_hash

      oldpwd = user_hash[:password]
      newpwd = generate_pwd

      # work
      # auth admin
      @token = auth_user_hash(@admin_hash)

      # work
      put '/users/password', {"username" => user_hash[:username], "newPassword" => newpwd}, {"token" => @token}

      #
      resp = last_response

      expect(resp.status).to eq 403


      # can login with old pwd
      token = auth_user(user_hash[:username], oldpwd)
      expect(token.length).to be > 1

      # cannot login with new pwd
      token = auth_user(user_hash[:username], newpwd)
      expect(token).to be nil

    end


  end
end
