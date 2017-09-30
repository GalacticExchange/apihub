RSpec.describe "Remove app", :type => :request do

  before :each do
    stub_create_node_all

    # user
    @user, @cluster = create_user_active_and_create_cluster

    # auth
    @token = auth_token @user


  end

  after :each do

  end

  describe "remove active app" do
    before :each do
      # app
      @app, @node = create_app_active(@cluster)
    end

    it "active app" do

      # work
      delete_json '/applications', {applicationID: @app.uid}, {token: @token}

      # check
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      @app.reload

      expect(@app.removed?).to eq true

      @app.containers.each do |container|
        expect(container.removed?).to eq true
      end

    end
  end

  describe "remove broken app" do
    before :each do
      # app
      @app, @node = create_app_install_error(@cluster)
    end


    it 'broken app' do
      # work
      delete_json '/applications', {applicationID: @app.uid}, {token: @token}

      # check
      resp = last_response
      data = JSON.parse(resp.body)

      #
      expect(resp.status).to eq 200

      @app.reload

      expect(@app.removed?).to eq true


      @app.containers.each do |container|
        expect(container.removed?).to eq true
      end
    end


  end


end
