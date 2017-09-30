describe "create user", :type => :feature do
  describe 'create user by invite' do
    before :each do
      # create admin user
      @admin = create_user_active_and_create_cluster

      # invite
      @invite_email =  generate_email
      res_invite = Gexcore::InvitationsService.send_invitation(@admin.team_id, @invite_email, @admin)

      @invitation = Invitation.where(:to_email=>@invite_email).first
      @invitation_token = @invitation.uid

      @url_invite_accept = Gexcore::InvitationsService.get_link(@invitation_token)

      #
      @user_hash = build_user_hash
      @user_hash[:email] = @invite_email

      ActiveRecord::Base.connection.commit_db_transaction
    end

    it "accept invitation - show form" do
      ActiveRecord::Base.connection.commit_db_transaction


      visit @url_invite_accept

      expect(current_path).to eq "/users/new"
    end
  end


end
