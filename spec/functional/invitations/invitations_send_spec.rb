RSpec.describe "Send invitation to team", :type => :request do

  describe 'send invitation' do

    before :each do
      stub_create_user_all

      #
      @admin_hash = build_user_hash
      @admin = create_user_active @admin_hash
      @team = @admin.team

      #
      @invite_email =  generate_email

      # stub permissions - # stub can? => true
      stub_user_can_true
    end

    after :each do

    end

    describe 'success' do

      it 'add invitation to DB' do
        # prepare
        #work
        expect{
          Gexcore::InvitationsService.send_invitation(@admin.team_id, @invite_email, @admin)
        }.to change{Invitation.count}.by(1)

      end

      it 'invitation row in DB' do
        #work
        res = Gexcore::InvitationsService.send_invitation(@admin.team_id, @invite_email, @admin)
        invitation = @team.invitations.where(:from_user_id => @admin.id).first

        expect(invitation.uid).not_to be nil
        expect(invitation.team_id).to eq (@admin.team_id)
        expect(invitation.to_email).to eq (@invite_email)
        expect(invitation.invitation_type).to eq (Invitation::TYPE_MEMBER)
        expect(invitation.status).to eq (Invitation::STATUS_NOT_ACTIVATED)

      end

      it 'mail' do
        #
        message_delivery = instance_double(ActionMailer::MessageDelivery)
        expect(UsersMailer).to receive(:invitation_email).and_return(message_delivery)
        expect(message_delivery).to receive(:deliver_later)

        #
        res = Gexcore::InvitationsService.send_invitation(@admin.team_id, @invite_email, @admin)

      end

      it 'add log_user_action to DB' do
        #work
        #expect{
        #  res = Apiservice::InvitationService.send_invitation(@admin.team_id, @invite_email, @admin)
        #}.to change{LogUserAction.count}.by(1)
      end

      it 'add log_access to DB' do
        #work
        #expect{
        #  res = Apiservice::InvitationService.send_invitation(@admin.team_id, @invite_email, @admin)
        #}.to change{LogAccess.count}.by(1)
      end
    end

    describe 'no permissions' do

      it 'no permissions' do
        # prepare

        # stub can? => false
        stub_user_can_false

        #work
        res = Gexcore::InvitationsService.send_invitation(@admin.team_id, @invite_email, @admin)

        expect(res.http_status).to be 403
      end

    end

    describe 'errors' do

      it 'invited user exists in our team => 400' do
        # prepare
        user2 = build_user_hash
        user2[:email] = @invite_email
        user2[:teamname] = @admin.team.name

        user = create_user_active_in_team(@admin.team_id, user2)

        # stub can? => true
        stub_user_can_true

        # work
        res = Gexcore::InvitationsService.send_invitation(@admin.team_id, user2[:email], @admin)

        expect(res.http_status).to be 400
      end

      it 'invited user exists in another team => 400' do
        # prepare
        user2 = create_user_active

        # stub can? => true
        stub_user_can_true

        # work
        res = Gexcore::InvitationsService.send_invitation(@admin.team_id, user2.email, @admin)

        expect(res.http_status).to be 400
      end

    end
  end



end


