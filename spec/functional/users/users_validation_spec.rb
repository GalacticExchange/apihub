RSpec.describe "Validate user", :type => :request do

  before :each do
    @lib = Gexcore::UsersCreationService
    @resp = Gexcore::Response

    @user_hash = build_user_hash
    @user = @lib.build_user_from_params @user_hash

  end


  describe 'validations' do
    before :each do

    end



    it "username valid" do
      # prepare
      good_list = ["dfghsdfg", "asd2", "as", "df-sd-fg", "AfAaSdDGF"]


      good_list.each do |s|
        @user.username = s
        expect(@user.valid?).to eq true
      end

    end

    it 'email valid' do
      # prepare
      good_list = ["Asdf@dFg....rsdFg"]

      good_list.each do |s|
        @user.email = s

        expect(@user.valid?).to eq true
      end

    end




    describe 'errors' do

      it 'username not valid' do
        # prepare
        bad_list = ["dfghsdfg-", "q", "4fod", "sdf--sdfg", "dfasd_sdfg", "-sdfg", "kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk33", 'иваныч','ali baba', 'it_is', 'big$dollar']


        bad_list.each do |s|
          @user.username = s

          expect(@user.valid?).to eq false
        end

      end

      it 'username used' do
        #
        stub_create_user_all

        res_user = @lib.create_user_active(@user, @sysinfo)


        # try to add with the same email
        n_old = User.count

        # user2
        user_hash2 = @user_hash.clone
        user_hash2[:email] = 'new'+user_hash2[:email]
        user_hash2[:password] = user_hash2[:password]+'111'
        user2 = @lib.build_user_from_params user_hash2

        res = @lib.create_user_active(user2, @sysinfo)

        #
        expect(res.success?).to be_falsey
        expect(User.count).to eq n_old

        # error
        #expect(res.error_name_small).to eq 'user_create_username_used'

      end

      it 'email not valid' do
        # prepare
        bad_list = ["blabla@@dot.com", "blabla@com", "Asdf@dfg.rsdfg.", "asdf@sd,sdf", "asdf@sd,.sdf"]

        bad_list.each do |s|
          @user.email = s

          expect(@user.valid?).to eq false
        end

      end

      it 'email used' do
        #
        stub_create_user_all

        res_user = @lib.create_user_active(@user, @sysinfo)


        # try to add with the same email
        n_old = User.count

        #
        user_hash2 = @user_hash.clone
        user_hash2[:username] = user_hash2[:username]+'new'
        user_hash2[:password] = user_hash2[:password]+'111'
        user2 = @lib.build_user_from_params user_hash2

        res = @lib.create_user_active(user2, @sysinfo)

        #
        expect(res.success?).to be_falsey
        expect(User.count).to eq n_old

        # error
        #expect(res.error_name_small).to eq 'user_create_email_used'

      end



    end

  end

end
