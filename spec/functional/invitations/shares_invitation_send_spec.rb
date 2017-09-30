RSpec.describe "Send invitation to share cluster", :type => :request do
  before :each do
    @clsResp = Gexcore::Response
    @lib = Gexcore::UsersCreationService

    #
    stub_create_user_all
    stub_create_cluster_all
  end

  describe 'send share invite' do

    before :each do
      # create user with cluster
      @admin, @cluster = create_user_and_cluster_onprem

      # user to share
      @share_email =  generate_email

    end

    after :each do

    end


    it 'data in DB' do
      # work
      res = Gexcore::InvitationsService.send_share_invitation(@admin, @share_email, @cluster.id)

      # expectation
      row = Invitation.where(to_email: @share_email).first

      expect(row.uid.length).to be > 2
      expect(row.status).to eq Invitation::STATUS_NOT_ACTIVATED
      expect(row.invitation_type).to eq Invitation::TYPE_SHARE
      expect(row.cluster_id).to eq @cluster.id
      expect(row.team_id).to eq @admin.team_id
      expect(row.from_user_id).to eq @admin.id


    end

    it 'mail' do

      #
      message_delivery = instance_double(ActionMailer::MessageDelivery)
      expect(UsersMailer).to receive(:share_invitation_email).and_return(message_delivery)
      expect(message_delivery).to receive(:deliver_later)

      #
      res = Gexcore::InvitationsService.send_share_invitation(@admin, @share_email, @cluster.id)

    end


  end



end


