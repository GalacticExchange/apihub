RSpec.describe "validate invitation token", :type => :request do

  before :each do
    #
    stub_create_cluster_all

    #
    @lib = Gexcore::UsersCreationService
    @libInvitations = Gexcore::InvitationsService
    @clsResp = Gexcore::Response
  end


  describe 'validate invitation token' do

    before :each do
      @admin_hash = build_user_hash
      @admin = create_user_active_and_create_cluster @admin_hash

      # invite
      @invite_email = generate_email
      res_invite = @libInvitations.send_invitation(@admin.team_id, @invite_email, @admin)

      @invitation = Invitation.where(:to_email=>@invite_email).first
      @invitation_token = @invitation.uid


      # auth main user
      @token = auth_user_hash(@admin_hash)


    end

    after :each do
      Timecop.return
    end



    it 'non exist token' do
      new_token = Gexcore::TokenGenerator.generate_invitation_token

      # work
      post '/userInvitations/validate', {token: new_token}, {}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 400
      expect(resp_errorname(resp_data)).to eq 'token_notfound'
    end

    it 'token used' do

      # make accepted
      @invitation.make_accepted!

      # work
      post '/userInvitations/validate', {token: @invitation_token}, {}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 400
      expect(resp_errorname(resp_data)).to eq 'token_used'
    end

    it 'token expired' do

      # make accepted
      @invitation.make_deleted!

      # work
      post '/userInvitations/validate', {token: @invitation_token}, {}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 400
      expect(resp_errorname(resp_data)).to eq 'token_expired'
    end

    it 'very old token' do

      # wait 3 months
      now = Time.now.utc
      Timecop.freeze( (3.months).since(now))

      # work
      post '/userInvitations/validate', {token: @invitation_token}, {}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 400
      expect(resp_errorname(resp_data)).to eq 'token_expired'
    end

  end
end
