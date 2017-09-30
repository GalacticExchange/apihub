RSpec.describe "user creation", :type => :request do

  before :each do
    @lib = Gexcore::UsersCreationService
    @clsResp = Gexcore::Response

    @sysinfo = build_sysinfo

  end


  describe 'create user with invitation token' do

    before :each do
      # create admin user
      @admin = create_user_active

      # invite
      @invite_email =  generate_email
      res_invite = Gexcore::InvitationsService.send_invitation(@admin.team_id, @invite_email, @admin)

      @invitation = Invitation.where(:to_email=>@invite_email).first
      @invitation_token = @invitation.uid


      #
      @user_hash = build_user_hash
      @user_hash[:email] = @invite_email
      #@user_hash[:username] = @invite_email
      @user_post = build_user_create_post @user_hash
      [:teamname].each{|f| @user_post.delete(f)}
      @user_post[:token] = @invitation_token

    end


    describe 'success' do

      before :each do
        post_json '/users', @user_post, {}

        #
        @resp = last_response
        @resp_data = JSON.parse(@resp.body)

      end

      it "ok - response" do
        expect(@resp.status).to eq(200)

      end


      it "ok - user in DB" do
        # check
        user = User.get_by_email(@invite_email)

        #
        expect(user.status).to eq User::STATUS_ACTIVE
        expect(user.team_id).to eq @admin.team_id
        #expect(user.group_id).to eq Group.group_user.id

        User::FIELDS_COMMON.each do |f|
          expect(user[f.to_sym]).to eq @user_hash[f.to_sym]
        end

      end

    end

    it 'ok - send email' do
      message_delivery = instance_double(ActionMailer::MessageDelivery)
      expect(UsersMailer).to receive(:welcome_email).with(@invite_email).and_return(message_delivery)
      expect(message_delivery).to receive(:deliver_later)

      #
      post_json '/users', @user_post, {}
    end

=begin
### with site

require 'spec_helper.rb'

RSpec.describe "accept invitation", :type => :request do

  describe 'accept invitation' do

  before :each do
    @sysinfo = JSON.parse(File.read('spec/data/cluster_body.txt'))

    #
    @username =  generate_email
    @share_username =  generate_email
    @pwd = generate_pwd

    @fields = {firstname: generate_name, lastname: generate_name}
    @fields_post = {firstName: @fields[:firstname], lastName: @fields[:lastname]}


    # ansible stub
    allow_any_instance_of(Gexcore::AnsibleRequest).to receive(:run).and_return true

    # for user create
    @lib.create_user_not_verified(@username, @pwd, @fields, @sysinfo)
    @admin = User.get_by_email @username
    @res = @lib.verify_user @admin.verification_token

    # auth main user
    @token = feature_auth_user(@username, @pwd)


    # invite
    res_invite = Gexcore::InvitationService.send_invitation(@admin.main_cluster_id, @share_username, @admin)

    @invitation = Invitation.where(:to_email=>@share_username).first
    @invitation_token = @invitation.uid


  end

  after :each do
    #Gexcore::Service.del_user @username
  end


  describe 'url /inviteaccept' do

    def make_url(token)

      '/inviteaccept/'+token
    end

    describe 'accept link' do

      it 'good token' do
        token = '1111333444'

        #
        get make_url(token)

        #
        resp = last_response

        expect(resp.status).to eq 302
        expect(resp.headers['Location']).to match(/\/userInvitations\/accept\/\?invitationToken=#{token}/)

      end

      it 'bad token' do
        token = '11@11333=444'

        #
        get make_url(token)

        #
        resp = last_response

        expect(resp.status).to eq 400

      end
    end
  end


  describe 'accept' do

    before :each do

    end


    def goto_accept(token)
      data = {'invitationToken'=>token}

      # work
      get '/userInvitations/accept/?invitationToken='+token, data, {}
    end


    it 'redirect to /users/new' do
      goto_accept(@invitation_token)

      #
      resp = last_response

      expect(resp.status).to eq 302
      expect(resp.headers['Location']).to match(/\/users\/new/)

    end

    it 'non exist token' do
      new_token = Gexcore::TokenGenerator.generate_invitation_token

      # work
      goto_accept new_token

      resp = last_response

      #
      expect(resp.status).to eq 403
    end

    it 'token used' do

      # make accepted
      @invitation.make_accepted!

      # try
      goto_accept(@invitation_token)

      #
      resp = last_response

      #
      expect(resp.status).to eq 400
    end

  end
end

=end


    describe 'errors' do

      it 'cannot change email from invitation' do
        # change email
        new_email = generate_email
        @user_post[:email] = new_email

        #
        post_json '/users', @user_post, {}

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        expect(resp.status).to eq 400

        user = User.get_by_email new_email
        expect(user).to be_nil

        user2 = User.get_by_email @invitation.to_email
        expect(user2).to be_nil

      end

      it 'cannot use the invitation twice' do
        # do the work
        post_json '/users', @user_post, {}

        # use again
        n_old = User.count

        post_json '/users', @user_post, {}

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        expect(resp.status).to eq 400
        expect(User.count).to eq n_old

      end

      it 'cannot use other invitations after accept' do
        # prepare

        # send several invitations
        1.upto(4) do |i|
          Gexcore::InvitationsService.send_invitation(@admin.team_id, @invite_email, @admin)
        end

        # invite another user
        invite_username2 = generate_email
        Gexcore::InvitationsService.send_invitation(@admin.team_id, invite_username2, @admin)

        #
        invitations = Invitation.where(:to_email=>@invite_email).all
        n_invitations = invitations.count

        invitation = invitations[2]
        invitation_old = invitations[0]

        # accept one invitation
        @user_post['token'] = invitation.token
        post_json '/users', @user_post, {}


        # work - use again
        n_old = User.count

        # try accept another invitation
        @user_post['token'] = invitation_old.token
        post_json '/users', @user_post, {}

        #
        resp = last_response
        resp_data = JSON.parse(resp.body)

        expect(resp.status).to eq 400

        # check. user not added
        expect(User.count).to eq n_old

        # check. invitation expired
        invitation_old.reload
        expect(invitation_old.expired?).to eq true

      end

    end


  end


end
