RSpec.describe "properties", :type => :request do

  describe 'properties' do

    before :each do
      # for user create
      @lib = Gexcore::OptionService

      #
      stub_create_user_all
      stub_create_cluster_all

      # create user with cluster
      @admin = create_user_active
      #
      @user = create_user_active_in_team(@admin.team_id)

      #
      stub_user_can_true

      #
      @name = 'opt'+Gexcore::Common.random_string(12)
    end

    after :each do

    end

    describe 'success' do

      before :each do

      end


      it 'get value' do
        skip

        # work
        res = @lib.get_option("name")

        # check
        expect(res).to be nil

      end

    end

    describe 'without cache' do

    end

    describe 'cache' do

    end

    describe 'errors' do
      it 'nil' do
        # work
        res = @lib.get_option(@name)

        # check
        expect(res.success?).to eq false

      end

    end
  end
end
