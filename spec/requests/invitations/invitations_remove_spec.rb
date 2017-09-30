RSpec.describe "invitation remove", :type => :request do
  before :each do
    @lib = Gexcore::InvitationsService

    # stub
    stub_create_cluster_all
  end


  describe 'remove invitation' do

    before :each do
      #
      @admin_hash = build_user_hash
      @admin = create_user_active_and_create_cluster @admin_hash
      @cluster = @admin.home_cluster
      @team = Team.find(@cluster.team_id)
    end

    after :each do

    end

    it 'delete invitation' do
      ##prepare
      victim_email = generate_email

      # send invitation to user
      @lib.send_invitation(@admin.team_id, victim_email, @admin)

      # auth user
      token = auth_user_hash(@admin_hash)

      # find invitation
      invitation = Invitation.where(status: Invitation::STATUS_NOT_ACTIVATED, to_email: victim_email).first

      # work
      delete_json '/invitations', {}, {"id" => invitation.id, "token" => token}

      # check
      resp = last_response
      expect(resp.status).to eq 200

      #
      invitation = Invitation.where(status: Invitation::STATUS_NOT_ACTIVATED, to_email: victim_email).first

      #
      expect(invitation).to be nil

    end

    it 'delete share invitation' do
      ##prepare
      as_01_email = generate_email

      # send share invitation
      @lib.send_share_invitation(@admin, as_01_email, @admin.main_cluster_id)

      # auth user
      token = auth_user_hash(@admin_hash)

      # find invitation
      invitation = Invitation.where(status: Invitation::STATUS_NOT_ACTIVATED, to_email: as_01_email).first

      # work
      delete_json '/invitations', {"id" => invitation.id}, {"token" => token}

      # check
      invitation = Invitation.where(status: Invitation::STATUS_NOT_ACTIVATED, to_email: as_01_email).first
      #
      expect(invitation).to be nil

    end

  end
end
