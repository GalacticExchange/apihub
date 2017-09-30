RSpec.describe "Create user in test mode", :type => :request do

  before :each do
    @lib = Gexcore::UsersCreationService
    @resp = Gexcore::Response

    stub_create_user_all
  end


  describe 'create_user_by_phone' do
    before :each do
      @user_hash = build_user_hash

      @user = @lib.build_user_from_params @user_hash

      @user.phone_number = '+380570000000'

      @sysinfo = build_sysinfo

    end


    describe 'success' do

      it "result" do
        # work
        res = @lib.create_user_by_phone(@user, @sysinfo)


        # check
        expect(res.success?).to be true

        #
        token = res.sysdata[:token]

        # row in DB
        row = User.get_by_username @user_hash[:username]

        expect(row.status).to eq User::STATUS_ACTIVE

        # team row in DB
        team = Team.get_by_name @user_hash[:teamname]

        expect(team.status).to eq Team::STATUS_ACTIVE

      end

      it 'send email' do
        skip

        #
        message_delivery = instance_double(ActionMailer::MessageDelivery)
        expect(UsersMailer).to receive(:verification_email).with(@user_hash[:email], anything).and_return(message_delivery)
        expect(message_delivery).to receive(:deliver_later)


        #
        @res = @lib.create_user_not_verified(@user, @sysinfo)
      end
    end





  end


end
