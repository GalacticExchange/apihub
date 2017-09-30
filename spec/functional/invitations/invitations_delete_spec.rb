RSpec.describe "Delete Invitations", :type => :request do

  before :each do
    #
    @lib = Gexcore::InvitationsService

    #
    stub_create_user_all
    stub_create_cluster_all
  end

  describe 'delete' do
    before :each do

      # user
      @admin, @cluster = create_user_and_cluster_onprem


      #
      stub_user_can_true

    end


    it 'delete invitation' do
      ##prepare
      as_01_email = generate_email
      as_02_email = generate_email
      as_03_email = generate_email

      # send invitation to users
      ss_01 = @lib.send_invitation(@admin.team_id, as_01_email, @admin)
      ss_02 = @lib.send_invitation(@admin.team_id, as_02_email, @admin)

      # send share invitation
      ss_03 = @lib.send_share_invitation(@admin, as_03_email, @cluster)

      invitation = Invitation.where(status: Invitation::STATUS_NOT_ACTIVATED, to_email: as_03_email).first

      # work
      res = @lib.delete_invitation(@admin, invitation.id)

      # check
      invitation = Invitation.where(status: Invitation::STATUS_NOT_ACTIVATED, to_email: as_03_email).first
      #
      expect(invitation).to be nil

      #LogSystem.where(id: 1..5000).destroy_all
      #User.where(id: 1..5000).destroy_all
    end

  end

end
