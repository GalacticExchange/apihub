RSpec.describe "Email - cluster info", :type => :request do

  describe "Content" do
    before :each do

    end

    it 'data' do
      #user = User.new
      email = generate_email
      token = Gexcore::TokenGenerator.generate_verification_token

      user = double(User, :email => email, :username => email, :firstname=>generate_name, :lastname=>generate_name)
      cluster = double(Cluster, :id=>999, :name => 'galacticname', :primary_admin=> user)
      allow(user).to receive(:home_cluster).and_return(cluster)


      #allow(User).to receive(:get_by_email).with(user.email).and_return(user)
      allow(Cluster).to receive(:find).with(cluster.id).and_return(cluster)

      #
      mail = UsersMailer.cluster_info_email(cluster.id)

      expect(mail.to).to eql([user.email])

      html = mail.body.parts.find {|p| p.content_type.match /html/}.body.raw_source
      text = mail.body.parts.find {|p| p.content_type.match /plain/}.body.raw_source
      # mail.body.encoded


      #
      [html, text].each do |t|
        expect(t).to match(cluster.name)

      end
    end

  end
end

