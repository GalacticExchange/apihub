RSpec.describe "Invitations to team", :type => :request do
  before :each do
    @lib = Gexcore::InvitationsService

    #
    stub_create_user_all
  end

  describe 'list invitations' do
    before :each do
      #
      @admin = create_user_active

      # stub can? => true
      stub_user_can_true

    end


    it 'get invitation list' do
      ##prepare
      as_01_email = generate_email

      ss_02 = @lib.send_invitation(@admin.team_id, as_01_email, @admin)

      invitation = Invitation.where(to_email: as_01_email).first.make_accepted!
      #
      as_02_email = generate_email
      as_03_email = generate_email

      # send invitation to users
      ss_02 = @lib.send_invitation(@admin.team_id, as_02_email, @admin)
      ss_03 = @lib.send_invitation(@admin.team_id, as_03_email, @admin)


      # work
      res = @lib.get_invitations_in_team(@admin, @admin.team_id)

      #
      expect(res.data[:invitations]).to be_truthy

      invitations = res.data[:invitations]

      expect(invitations.count).to eq 2

      #
      good_emails = [as_02_email, as_03_email]
      bad_emails = [as_01_email]

      invitations.each do |u|
        expect(good_emails.include? u[:email]).to be true
        expect(bad_emails.include? u[:email]).to be false
      end

    end




  end

end
