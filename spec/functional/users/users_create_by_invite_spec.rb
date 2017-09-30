RSpec.describe "Create user", :type => :request do

  before :each do
    @lib = Gexcore::UsersCreationService
    @resp = Gexcore::Response

    stub_create_user_all
  end



  describe 'create user with invitation token' do
    before :each do
      #
      stub_create_cluster_all


      # create admin user
      @admin, @cluster = create_user_active_and_create_cluster
      @team = @admin.team

      # invite
      @invite_email =  generate_email
      res_invite = Gexcore::InvitationsService.send_invitation(@admin.team_id, @invite_email, @admin)

      @invitation = Invitation.where(:to_email=>@invite_email).first
      @invitation_token = @invitation.uid

      #
      @user_hash = build_user_hash
      @user_hash[:email] = @invite_email
      @user_hash[:teamname] = @team.name

      @user = @lib.build_user_from_params @user_hash


    end


    describe 'method create_user_with_invitation_token' do

      it 'user in DB' do

        # work
        res = @lib.create_user_with_invitation_token @invitation_token, @user

        #
        user = User.get_by_email @invite_email

        # check: row in DB
        expect(user.status).to eq User::STATUS_ACTIVE
        expect(user.team_id).to eq @admin.team_id
        #expect(user.group_id_in_cluster).to eq Group.group_user.id

        expect(user.invitation_id).to eq @invitation.id

      end

      it 'invitation status' do

        # work
        res = @lib.create_user_with_invitation_token @invitation_token, @user

        invitation = Gexcore::InvitationsService.find_invitation_by_token(@invitation_token)

        # check: row in DB
        expect(invitation.status).to eq Invitation::STATUS_ACTIVATED

      end


      it 'expire other invitations' do

        # send several invitations
        1.upto(3) do |i|
          Gexcore::InvitationsService.send_invitation(@admin.team_id, @invite_email, @admin)
        end

        # invite another user
        invite_email2 = generate_email
        Gexcore::InvitationsService.send_invitation(@admin.team_id, invite_email2, @admin)


        # work - accept invite
        res = @lib.create_user_with_invitation_token @invitation_token, @user

        user = User.get_by_email @invite_email

        # check: invitations
        invitations_old = Invitation.where(to_email: @invite_email)

        invitations_old.each do |r|
          next if r.uid == @invitation_token

          expect(r.status).to eq Invitation::STATUS_EXPIRED
        end

        # do not touch invitations to another emails
        invitations2 = Invitation.where(to_email: invite_email2)

        invitations2.each do |r|
          expect(r.status).to eq Invitation::STATUS_NOT_ACTIVATED
        end

      end

      it 'cannot change email from invitation' do
        # work
        user_hash_new = @user_hash.clone
        user_hash_new[:email] = generate_email
        user_new = @lib.build_user_from_params user_hash_new

        res = @lib.create_user_with_invitation_token @invitation_token, user_new

        # check: user not created
        expect(res.http_status).to eq 400

        #
        user = User.get_by_email @invite_email
        expect(user).to be_nil

        #
        user2 = User.get_by_email user_hash_new[:email]
        expect(user2).to be_nil
      end


      it 'access to clusters' do
        # work
        res = @lib.create_user_with_invitation_token @invitation_token, @user


        # check
        #user = res.data[:user_id]
        user = User.get_by_email @invite_email

        expect(ClusterAccess.has_access?(@cluster.id, user.id)).to eq true

      end

    end

  end


end
