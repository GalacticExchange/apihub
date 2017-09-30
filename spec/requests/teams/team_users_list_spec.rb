RSpec.describe "Users list in team", :type => :request do
  before :each do
    #
    stub_create_cluster_all
  end

  describe 'get users list in team' do

    before :each do
      #
      @admin_hash = build_user_hash
      @admin = create_user_active_and_create_cluster @admin_hash
      @team = @admin.team

      #
      @user1_hash = build_user_hash
      @user1 = create_user_active_in_team @team.id, @user1_hash

      @user2_hash = build_user_hash
      @user2 = create_user_active_and_create_cluster @user2_hash

      # auth user
      @token = auth_user_hash(@admin_hash)
    end

    after :each do

    end

    it "ok" do
      # work
      get_json '/teamUsers', {}, {"token" => @token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      rows = resp_data["users"]


      good_names = [@admin.username, @user1_hash[:username]]
      bad_names = [@user2_hash[:username]]

      rows.each do |u|
        expect(good_names.include? u["username"]).to be true
        expect(bad_names.include? u["username"]).to be false
      end

      # data
      row = rows[0]
      expect(row['firstName']).to be_truthy
      expect(row['lastName']).to be_truthy
      expect(row['role']).to be_truthy

    end

  end


  describe '2 - get users list in team' do

    before :each do
      #
      @admin_hash = build_user_hash
      @admin = create_user_active_and_create_cluster @admin_hash
      @team = @admin.team
    end

    after :each do

    end

    it "ok" do
      # prepare
      user_hash = build_user_hash
      user = create_user_active_and_create_cluster user_hash
      # create victim_01 in user team
      user_hash_01 = build_user_hash
      victim_01 = create_user_active_in_team(user.team_id, user_hash_01)

      # create victim_02 in @admin team
      user_hash_02 = build_user_hash
      victim_02 = create_user_active_in_team(@admin.team_id, user_hash_02)

      # auth user
      token = auth_user_hash(@admin_hash)

      # work
      get_json '/teamUsers', {}, {"token" => token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      good_names = [@admin.username, victim_02.username]
      bad_names = [user.username, victim_01.username]

      resp_data["users"].each do |u|
        expect(good_names.include? u["username"]).to be true
        expect(bad_names.include? u["username"]).to be false
      end

    end

  end
end
