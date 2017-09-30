RSpec.describe "Email - verification", :type => :request do

  describe "Content" do
    before :each do

    end

    it 'data' do
      #email = generate_email
      #pwd = generate_pwd
      #fields = {'firstname'=>'xxx', 'lastname'=>'222'}
      #Apiservice::UsersCreationLib.create_user_not_verified(email, pwd, fields)
      #@user = User.get_by_email email


      #user = User.new
      #@user = double(User)
      email = generate_email
      token = Gexcore::TokenGenerator.generate_verification_token

      user = double(User, :email => email, :username => email, :firstname=>generate_name, :lastname=>generate_name, :confirmation_token=>token)

      #allow(@user).to receive(:email).and_return("The RSpec Book")
      #user.stub(:email).and_return('I am writing')

      #allow(User).to receive(:get_by_email).with(user.email).and_return(user)
      allow(User).to receive(:get_by_email).and_return(user)

      mail = UsersMailer.verification_email(user.email, token)

      expect(mail.to).to eql([user.email])

      html = mail.body.parts.find {|p| p.content_type.match /html/}.body.raw_source
      text = mail.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
      # mail.body.encoded

      x = 0


      [html, text].each do |t|
        expect(t).to match('verify')

        expect(t).to match(user.confirmation_token)

        #expect(t).to match(user.firstname)
        #expect(t).to match(user.lastname)

      end
    end

  end
end

