RSpec.describe "Create user", :type => :request do

  before :each do
    @lib = Gexcore::UsersCreationService
    @resp = Gexcore::Response

    stub_create_user_all
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

      @user = @lib.build_user_from_params @user_hash

    end

    describe 'success' do
      before :each do
        @res = @lib.create_user_with_invitation_token(@invitation_token, @user)

      end

      it "ok - response" do
        expect(@res.success?).to eq true

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
        expect(user.invitation_id).to eq @invitation.id

      end

      it 'access to cluster' do
        expect(ClusterAccess.has_access?(@cluster.id, user.id)).to eq true

      end

      it 'set invitation status' do
        # check
        invitation = Invitation.where(uid: @invitation_token).first

        expect(invitation.status).to eq Invitation::STATUS_ACTIVATED
      end

    end

    it 'ok - send email' do
      #
      message_delivery = instance_double(ActionMailer::MessageDelivery)
      expect(UsersMailer).to receive(:welcome_email).with(@invite_email).and_return(message_delivery)
      expect(message_delivery).to receive(:deliver_later)

      #
      @res = @lib.create_user_with_invitation_token(@invitation_token, @user)
    end
  end


end
