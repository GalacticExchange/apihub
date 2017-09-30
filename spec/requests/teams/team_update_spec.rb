RSpec.describe "Team update info", :type => :request do
  before :each do
    #
    stub_create_cluster_all
  end


  describe 'put team info' do

    before :each do
      #
      @admin_hash = build_user_hash
      @admin = create_user_active_and_create_cluster @admin_hash
      @team = Team.find(@admin.team_id)
      # auth main user
      @token = auth_user_hash(@admin_hash)

    end

    after :each do

    end


    it "ok" do


      s = generate_text

      # work
      put_json '/teamInfo', {about: s}, {"token" => @token}

      @team.reload
      resp = last_response

      #
      expect(resp.status).to eq 200
      expect(@team.about).to eq s

    end

    it "no permissions" do
      #
      user_hash = build_user_hash
      user = create_user_active_in_team @team.id, user_hash
      # auth user
      user_token = auth_user_hash(user_hash)

      s = generate_text

      # work
      put_json '/teamInfo', {about: s}, {"token" => user_token}

      @team.reload

      resp = last_response
      #
      expect(resp.status).to eq 403

    end
  end
end
