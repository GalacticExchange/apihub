RSpec.describe "share invite", :type => :request do

  before :each do
    #
    stub_create_cluster_all

    #
    @lib = Gexcore::UsersCreationService
    @clsResp = Gexcore::Response
  end


  describe 'send share invite' do

    before :each do
      @admin_hash = build_user_hash
      @admin = create_user_active_and_create_cluster @admin_hash

      #
      @cluster = Cluster.find(@admin.main_cluster_id)


      # auth main user
      @token = auth_user_hash(@admin_hash)

      # user to share
      @share_email =  generate_email

    end

    after :each do

    end


    it "add invitation to DB" do
      # prepare
      count = Invitation.count

      # work
      post '/shareInvitations', {"email" => @share_email}, {"token" => @token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      # expectation
      expect(Invitation.count).to eq(count + 1)


    end

    it 'data in DB' do
      # work
      post '/shareInvitations', {"email" => @share_email}, {"token" => @token}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)

      # expectation
      row = Invitation.where(to_email: @share_email).first

      expect(row.uid.length).to be > 2
      expect(row.status).to eq Invitation::STATUS_NOT_ACTIVATED
      expect(row.invitation_type).to eq Invitation::TYPE_SHARE
      expect(row.cluster_id).to eq @admin.main_cluster_id
      expect(row.team_id).to eq @admin.team_id
      expect(row.from_user_id).to eq @admin.id


    end

    it 'mail' do
      message_delivery = instance_double(ActionMailer::MessageDelivery)
      expect(UsersMailer).to receive(:share_invitation_email).and_return(message_delivery)
      expect(message_delivery).to receive(:deliver_later)

      # work
      post '/shareInvitations', {"email" => @share_email}, {"token" => @token}

    end


  end
end
