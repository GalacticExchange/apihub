RSpec.describe "Invitations to share", :type => :request do
  before :each do
    @lib = Gexcore::InvitationsService

    #
    stub_create_user_all
    stub_create_cluster_all
  end

  describe 'list invitations' do
    before :each do
      #
      @admin, @cluster = create_user_and_cluster_onprem

      # stub can? => true
      stub_user_can_true

    end


    it 'get share_invitation list' do
      ##prepare
      as_01_username = generate_username
      as_01_email = generate_email

      ss_02 = @lib.send_share_invitation(@admin, as_01_email, @cluster)

      # change status invitation STATUS_ACTIVATED
      invitation = Invitation.where(to_email: as_01_email).first.make_accepted!


      #
      as_02_email = generate_email
      as_03_email = generate_email

      # send invitation to users
      ss_02 = @lib.send_share_invitation(@admin, as_02_email, @cluster)
      ss_03 = @lib.send_share_invitation(@admin, as_03_email, @cluster)

      # work
      res = @lib.get_share_invitations_in_cluster(@admin, @cluster)

      #
      expect(res.data[:invitations]).to be_truthy

      invitations = res.data[:invitations]

      expect(invitations.count).to eq 2

      good_emails = [as_02_email, as_03_email]
      bad_emails = [as_01_email]

      invitations.each do |u|
        expect(good_emails.include? u[:email]).to be true
        expect(bad_emails.include? u[:email]).to be false
      end

    end
end

end
