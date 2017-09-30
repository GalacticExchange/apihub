RSpec.describe "Email - invitation", :type => :request do

  describe "Content" do
    before :each do

    end

    it 'data' do

      uid = Gexcore::TokenGenerator.generate_invitation_token
      email = generate_email
      id = 1
      user_id = 22

      invitation = double(Invitation, :uid => uid, :id => id, :to_email => email, :from_user_id => user_id)


      #allow(@user).to receive(:email).and_return("The RSpec Book")
      #user.stub(:email).and_return('I am writing')

      allow(Invitation).to receive(:find).with(invitation.id).and_return(invitation)

      mail = UsersMailer.invitation_email(invitation.id)

      expect(mail.to).to eql([invitation.to_email])

      html = mail.body.parts.find {|p| p.content_type.match /html/}.body.raw_source
      text = mail.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
      # mail.body.encoded

      x = 0


      [html, text].each do |t|
        expect(t).to match('inviteaccept')

        expect(t).to match(invitation.uid)

      end
    end

  end
end

