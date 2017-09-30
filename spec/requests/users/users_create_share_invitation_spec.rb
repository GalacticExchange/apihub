RSpec.describe "user creation", :type => :request do

  before :each do
    @lib = Gexcore::UsersCreationService
    @clsResp = Gexcore::Response

    @sysinfo = build_sysinfo

  end


  describe 'create user with share token' do

    before :each do
      # create admin user
      @admin, @cluster = create_user_active_and_create_cluster

      # invite
      @invite_email =  generate_email
      res_invite = Gexcore::InvitationsService.send_share_invitation(@admin, @invite_email, @cluster.id)

      @invitation = Invitation.where(:to_email=>@invite_email).first
      @invitation_token = @invitation.uid


      #
      @user_hash = build_user_hash
      @user_hash[:email] = @invite_email

      @user_post = build_user_create_post @user_hash, {token: @invitation_token}

    end

    describe 'success' do

      before :each do
        post_json '/users', @user_post, {}

        #
        @resp = last_response
        @resp_data = JSON.parse(@resp.body)

      end

      it "ok - response" do
        expect(@resp.status).to eq(200)

      end


      it "ok - user in DB" do
        # check
        user = User.get_by_email(@invite_email)

        #
        expect(user.status).to eq User::STATUS_ACTIVE
        expect(user.team_id).not_to eq @admin.team_id

        User::FIELDS_COMMON.each do |f|
          expect(user[f.to_sym]).to eq @user_hash[f.to_sym]
        end

        #
        expect(ClusterAccess.has_access?(@cluster.id, user.id)).to eq true


        # cluster should be created


      end


      it 'set invitation status' do
        # check
        invitation = Invitation.where(uid: @invitation_token).first

        expect(invitation.status).to eq Invitation::STATUS_ACTIVATED
      end

    end


    it 'call create_cluster for user' do
      #
      expect(Gexcore::Clusters::Service).to receive(:create_cluster).and_call_original

      # do the job
      post_json '/users', @user_post, {}

      #
      resp = last_response
      resp_data = JSON.parse(resp.body)


    end


    it 'ok - send email' do
      message_delivery = instance_double(ActionMailer::MessageDelivery)
      expect(UsersMailer).to receive(:welcome_email).with(@invite_email).and_return(message_delivery)
      expect(message_delivery).to receive(:deliver_later)

      #
      post_json '/users', @user_post, {}
    end

  end
  
end
