RSpec.describe "User password", :type => :request do
  before :each do
    stub_create_user_all

  end

  describe 'send link to reset password' do
    before :each do
      @user_hash = build_user_hash
      @user = create_user_active @user_hash

    end

    describe 'success' do
      it 'send reset link' do
        #
        res = Gexcore::UsersService.send_resetpassword_link(@user.username)

        user = User.find(@user.id)

        # check
        expect(res.http_status).to eq 200

        expect(user.reset_password_token).not_to be_nil

      end

      it 'ok by email' do

      end


      it 'mail' do
        # check
        message_delivery = instance_double(ActionMailer::MessageDelivery)
        expect(UsersMailer).to receive(:resetpassword_email).with(@user.id, anything).and_return(message_delivery)
        expect(message_delivery).to receive(:deliver_later)

        # work
        res = Gexcore::UsersService.send_resetpassword_link(@user.username)


      end

    end
  end
end
