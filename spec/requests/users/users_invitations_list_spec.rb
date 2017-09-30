RSpec.describe "invitations list", :type => :request do
  before :each do
    #
    stub_create_user_all

    #
    @lib = Gexcore::UsersCreationService
    @clsResp = Gexcore::Response

  end

  describe 'get invitations list' do

    before :each do
      @admin_hash = build_user_hash
      @admin = create_user_active @admin_hash

      # invite
      @invite_email = generate_email
      res_invite = Gexcore::InvitationsService.send_invitation(@admin.team_id, @invite_email, @admin)

      @invitation = Invitation.where(:to_email=>@invite_email).first
      @invitation_token = @invitation.uid


      # auth main user
      @token = auth_user_hash(@admin_hash)


    end

    after :each do

    end

    it "ok - response" do
      # prepare

      # work
      get_json '/userInvitations', {}, {"tokenId" => @token}

      resp = last_response
      resp_data = JSON.parse(resp.body)

      # expectation
      expect(resp_data['invitations'][0]['email']).to eq(@invite_email)
      #expect(@resp_data).to be_empty

    end

  end
end
