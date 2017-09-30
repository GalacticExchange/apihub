RSpec.describe "Users update info", :type => :request do
  before :each do
  end


  describe 'put user info' do

    before :each do
      #
      @admin_hash = build_user_hash
      @admin = create_user_active @admin_hash
    end

    after :each do

    end


    it "ok" do
      # auth main user
      token = auth_user_hash(@admin_hash)


      # work
      put_json '/userInfo', {"firstName" => "John", "lastName" => "Doe2"}, {"token" => token}

      @admin.reload

      #
      expect(@admin.firstname).to eq "John"
      expect(@admin.lastname).to eq "Doe2"

    end
  end
end
