RSpec.describe "Validate team", :type => :request do

  before :each do
    @lib = Gexcore::UsersCreationService
    @resp = Gexcore::Response

    @user_hash = build_user_hash
    @user = @lib.build_user_from_params @user_hash
    @team = @user.team

  end


  describe 'validations' do
    before :each do

    end



    it "valid" do
      # prepare
      good_list = ["dfghsdfg", "asd2", "as", "df-sd-fg", "AfAaSdDGF"]


      good_list.each do |s|
        @team.name = s
        expect(@team.valid?).to eq true
      end



    end


    describe 'errors' do

      it 'name not valid' do
        # prepare
        bad_list = ["dfghsdfg-", "q", "4fod", "sdf--sdfg", "dfasd_sdfg", "-sdfg", "kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk33"]


        bad_list.each do |s|
          @user.username = s

          expect(@user.valid?).to eq false
        end

      end

    end

  end

end
