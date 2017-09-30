RSpec.describe "Auth", :type => :request do
  before :each do
    @lib = Gexcore::AuthService
  end

  describe 'login' do
    before :each do
      stub_create_user_all

      @user_hash = build_user_hash
      @user = create_user_active(@user_hash)

      @username = @user_hash[:username]
      @pwd = @user_hash[:password]
    end

    it 'login' do

      res = @lib.auth(@username, @pwd)

      #
      data = res.data

      #
      expect(data[:token].length).to be > 2
    end

  end

  describe 'token' do
    before :each do
      stub_create_user_all

      @user_hash = build_user_hash
      @user = create_user_active(@user_hash)

      @username = @user_hash[:username]
      @pwd = @user_hash[:password]
    end

    it 'validate token' do
      res = @lib.auth(@username, @pwd)

      #
      token = res.data[:token]

      #
      res_data = @lib.validate_token(token)
      data = res_data.data

      #
      expect(data[:username].length).to be >0


    end

    it 'bad token' do
      res = @lib.auth(@username, @pwd)

      #
      token = res.data[:token]

      bad_token = token+'000'

      #
      res_valid = @lib.validate_token(bad_token)

      #
      expect(res_valid.error?).to eq true
    end

    it 'invalidate token' do
      # login
      res_login = @lib.auth(@username, @pwd)

      token = res_login.data[:token]

      # check token is valid
      res_valid = @lib.validate_token(token)
      expect(res_valid.success?).to eq true

      # logout
      res_logout = @lib.invalidate_token(token)

      #
      res_valid = @lib.validate_token(token)

      expect(res_valid.success?).to eq false
    end

  end


end

