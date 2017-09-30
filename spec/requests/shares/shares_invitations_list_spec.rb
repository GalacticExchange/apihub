RSpec.describe "users share list for cluster", :type => :request do

  before :each do
    #
    stub_create_user_all
    stub_create_cluster_all

  end


  describe 'get share users list for cluster' do

    before :each do
      @lib = Gexcore::InvitationsService

      #
      @admin_hash = build_user_hash
      @admin = create_user_active_and_create_cluster @admin_hash
      @cluster = @admin.home_cluster
      @team = @cluster.team
    end

    after :each do

    end

    it "ok" do
      # prepare
      user_email = generate_email

      # count
      count = Invitation.count

      # auth user
      token = auth_user_hash(@admin_hash)

      # send share invitation
      @lib.send_share_invitation(@admin, user_email, @admin.main_cluster_id)

      #
      expect(Invitation.count).to eq (count + 1)

      # find invitation
      invitation = Invitation.where(status: Invitation::STATUS_NOT_ACTIVATED, to_email: user_email).first

      # work get invitations list
      get_json '/shareInvitations', {}, {"tokenId" => token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      res_invitation = resp_data["data"]["invitations"][0]
      expect(res_invitation["id"]).to eq invitation.id
      expect(res_invitation["email"]).to eq invitation.to_email
      expect(res_invitation["date"]).to eq Gexcore::Common.date_format(invitation.created_at)

    end

  end
end
