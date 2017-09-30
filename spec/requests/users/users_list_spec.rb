RSpec.describe "Users list", :type => :request do
  before :each do
    #
    stub_create_user_all
  end

  describe 'search users' do

    before :each do
      #
      @user1_hash = build_user_hash
      @user1 = create_user_active @user1_hash

      @user2_hash = build_user_hash
      @user2 = create_user_active @user2_hash

      @user3_hash = build_user_hash
      create_user_active_in_team(@user1.team_id, @user3_hash)

      # ES update
      User.__elasticsearch__.refresh_index!

      #sleep 5
    end

    it 'search simple' do
      # work
      get_json '/users', {q: @user2_hash[:username]}, {}

      #
      expect(response.status).to eq 200
      data = response_json

      #
      expect(data['total']).to eq 1

      row = data['result'][0]
      expect(row['username']).to eq @user2_hash[:username]
      expect(row['firstName']).to be_truthy
      expect(row['lastName']).to be_truthy
      expect(row['role']).to be_nil

    end

    it 'search with special symbols' do
      q = 'a['

      # work
      get_json '/users', {q: q}, {}

      #
      expect(response.status).to eq 200
      data = response_json

      #
      expect(data['total']).to eq 0

      #row = data['result'][0]
    end
  end

end
