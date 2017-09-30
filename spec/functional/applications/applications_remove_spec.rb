RSpec.describe "Remove application", :type => :request do

  before :each do
    # app
    @app, @node, @user = create_app_active



  end

  describe 'remove active app' do
    before :each do


    end

    it 'DB' do
      # pre-check
      expect(@app.status).to eq 'active'

      # work
      res = Gexcore::Applications::Service.remove_application(@app)

      # check
      expect(res.success?).to eq true

      # app data
      @app.reload

      expect(@app.status).to eq 'removed'

      # containers
      @app.containers.all.each do |container|
        expect(container.status).to eq 'removed'
      end


    end
  end




end


