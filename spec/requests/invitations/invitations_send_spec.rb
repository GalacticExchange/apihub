RSpec.describe "invite user", :type => :request do

  before :each do
    #
    stub_create_cluster_all

    #
    @lib = Gexcore::UsersCreationService
    @clsResp = Gexcore::Response
  end


  describe 'send invitation' do

    before :each do
      #
      @admin_hash = build_user_hash
      @admin = create_user_active_and_create_cluster @admin_hash

      #
      @invite_email =  generate_email

      # auth main user
      @token = auth_user(@admin.username, @admin_hash[:password])
    end

    after :each do

    end


    describe 'success path' do

      it "ok - response" do
        # prepare

        # work
        post '/userInvitations', {"email" => @invite_email}, {"token" => @token}

        resp = last_response
        resp_data = JSON.parse(resp.body)

        # expectation
        expect(resp.status).to eq(200)
        #expect(@resp_data).to be_empty

      end



      it "add invitation to DB" do
        # prepare
        count = Invitation.count

        # work
        post '/userInvitations', {"email" => @invite_email}, {"token" => @token}

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        # expectation
        expect(Invitation.count).to eq(count + 1)
        #expect(@resp_data).to be_empty

      end

      it 'mail' do
        #
        message_delivery = instance_double(ActionMailer::MessageDelivery)
        expect(UsersMailer).to receive(:invitation_email).and_return(message_delivery)
        expect(message_delivery).to receive(:deliver_later)

        # work
        post '/userInvitations', {"email" => @invite_email}, {"token" => @token}

      end

    end

    describe 'errors' do
      it "invited user exists in our team" do
        # prepare
        user2 = build_user_hash
        user2[:email] = @invite_email
        user2[:teamname] = @admin.team.name

        user = create_user_active_in_team(@admin.team_id, user2)

        # work
        post '/userInvitations', {"email" => @invite_email}, {"token" => @token}

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        # expectation
        expect(resp.status).to eq(400)
        #expect(@resp_data).to be_empty

      end
    end

  end



end
