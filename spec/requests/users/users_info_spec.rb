RSpec.describe "Users info", :type => :request do
  before :each do
  end


  describe 'get user info' do
    before :each do
      # stub
      stub_create_user_all

      #
      @admin_hash = build_user_hash
      @admin = create_user_active(@admin_hash)


    end

    after :each do

    end


    it "ok - another user" do
      # prepare
      user_hash = build_user_hash
      victim = create_user_active_in_team(@admin.team_id, user_hash)

      # auth main user
      token = auth_token @admin

      # work
      get_json '/userInfo', {"username" => user_hash[:username]}, {"tokenId" => token}

      #
      expect(response.status).to eq 200

      #
      data = response_json
      expect(data["user"]["username"]).to eq user_hash[:username]
      expect(data["user"]["firstName"]).to eq user_hash[:firstname]
      expect(data["user"]["lastName"]).to eq user_hash[:lastname]
      expect(data["user"]["role"]).to eq "user"

    end

    it "ok - herself" do
      # auth main user
      token = auth_token @admin

      # work
      get_json '/userInfo', {}, {"token" => token}

      #
      resp = last_response
      resp_data = response_json

      #
      user_data = resp_data["user"]
      expect(user_data["username"]).to eq @admin_hash[:username]
      expect(user_data["firstName"]).to eq @admin_hash[:firstname]
      expect(user_data["lastName"]).to eq @admin_hash[:lastname]
      expect(user_data["role"]).to eq "superadmin"

    end

  end
end
