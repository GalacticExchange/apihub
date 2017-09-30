RSpec.describe "Users", :type => :request do
  before :each do
    stub_create_user_all

  end

  describe 'update user info' do
    before :each do
      @user_hash = build_user_hash
      @user = create_user_active @user_hash

    end

    it 'update user info' do
      #
      params = {firstName: 'vasya', lastName: 'dedushka'}
      #
      fields_data = Gexcore::UsersService.get_fields_data_from_params(params)

      # work
      res = Gexcore::UsersService.update_user_info(@user.username, fields_data)

      @user.reload

      user = User.find(@user.id)
      # work
      expect(user.firstname).to eq "vasya"
      expect(user.lastname).to eq "dedushka"

    end
  end
end

