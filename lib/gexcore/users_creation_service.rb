module Gexcore
  class UsersCreationService < BaseService

    def self.is_test_mode_registration(u)
      #!Rails.env.production? &&
      return true if  Gexcore::Settings.TEST_PHONE_NUMBER==u.phone_number
      false
    end


    ###
    def self.build_user_from_params(params, from_admin = false)
      user = User.new

      user.username = params[:username] || ''
      user.email = params[:email] || ''
      user.phone_number = params[:phonefull] || params[:phoneNumber] || params[:phone_number] || ''
      user.registration_ip = params[:registration_ip] || ''
      user.country = params[:country] || ''
      user.password = params[:password] || ''
      user.admin_notes = {pwd: user.password} if from_admin

      teamname = params[:teamname]
      teamname ||= params[:team][:name] rescue nil
      teamname ||= params[:team_attributes][:name] rescue nil

      if user.team.nil?
        user.build_team
      end

      user.team.name = teamname.downcase unless teamname.nil?

      # fields
      fields_data = Gexcore::UsersService.get_fields_data_from_params(params)
      fields_data.each do |f,v|
        user[f.to_sym] = v
      end

      user
    end



    ### create new user and create team, make user superadmin of the team,
    # check phone number,
    # if user from US -> activate user, create cluster and send an SMS with password
    def self.create_user_by_phone(user, sysdata={}, registration_options={}, is_admin_mode=false, is_test_mode=false)
      res = Response.new
      token = ''

      begin
        #
        token = TokenGenerator.generate_verification_token
        user.confirmation_token = token
        user.confirmed_at = nil
        user.status = User::STATUS_NOT_VERIFIED
        user.registration_options = registration_options.to_json

        #
        res.sysdata[:token] = token

        #
        user.group_id = Group.group_superadmin.id

        # team
        user.team.uid = Gexcore::TokenGenerator.generate_team_uid
        user.team.status = user.status

        # phone
        if user.phone_number
          if !is_test_mode
            user.validate_phone

            #if !user.valid?
            #  raise 'Invalid phone'
            # end
          end
        end

        # country
        if is_test_mode
          user.country = Gexcore::Settings.TEST_USER_COUNTRY
        end

        # pwd
        if is_test_mode
          if is_admin_mode
            # do nothing - pwd should be provided
          else
            user.password = Gexcore::Settings.TEST_USER_PWD
          end
        else
          # generate password
          user.password = generate_random_password(8)
        end

        pwd = user.password
        res_user = user.save

        if !res_user
          # errors
          user.errors.full_messages.each do |msg|
            res.add_error_message msg
          end

          #
          status = user.valid? ? 500 : 400

          return res.set_error('user_create_error', '', "cannot save to table users", status)
        end

        # update team
        user.team.primary_admin_user_id = user.id
        res_team = user.team.save
        return res.set_error('user_create_error', '', "cannot update team.primary_admin_id") if !res_team


        # OK
        res.sysdata[:user_id] = user.id
        res.sysdata[:username] = user.username
        res.sysdata[:team_id] = user.team_id

        res.set_data

      rescue => e
        return res.set_error_exception("Cannot create user", e)
      end


      #
      user.reload
      res.sysdata[:user_id] = user.id


      # activate && send SMS or NOT

      is_phone_valid = check_phone_number(user.phone_number)

      to_activate = is_admin_mode || is_test_mode || is_phone_valid
      if to_activate
        # verify
        res_verify = Gexcore::UsersCreationService.verify_user(user.confirmation_token)
        gex_logger.log_response(res_verify, 'user_verified', "Email was verified: :email", 'user_verify_error')

        # email todo - fix email sending
        #UsersMailer.phone_verification_email(user.email).deliver_later
      end

      #
      to_send_sms = !is_admin_mode && !is_test_mode && is_phone_valid

      if to_send_sms
        res_sms = send_password_sms(user,pwd)

        if res_sms
          set_sms_sent_field(user)
        end
      end

      # bad phone
      if !to_activate && !to_send_sms
        UsersMailer.registration_email(user.email).deliver_later
      end

      #
      res
    end




    ### create new user and create team, make user superadmin of the team

    def self.create_user_active(user, sysdata={}, registration_options={}, is_admin_mode=false, is_test_mode=false)
      begin
        res = Response.new
        res.sysdata[:sysdata] = sysdata

        #
        user.confirmation_token = ''
        user.confirmed_at = Time.now.utc
        user.status = User::STATUS_ACTIVE
        user.registration_options = registration_options.to_json

        #
        user.group_id = Group.group_superadmin.id

        # create team
        #user.team.name # should be set before
        user.team.uid = Gexcore::TokenGenerator.generate_team_uid
        user.team.status = user.status


        # pwd
        if is_test_mode
          if is_admin_mode
            # do nothing - pwd should be provided
          else
            user.password = Gexcore::Settings.TEST_USER_PWD
          end
        else
          # generate password
          user.password = generate_random_password(8)
        end

        # phone
        if user.phone_number
          if !is_test_mode
            user.validate_phone

            #if !user.valid?
            #  raise 'Invalid phone'
            # end
          end
        end

        # country
        if is_test_mode
          user.country = Gexcore::Settings.TEST_USER_COUNTRY
        end

        #
        user.skip_confirmation!


        res_user = user.save

        if !res_user
          # errors
          user.errors.full_messages.each do |msg|
            res.add_error_message msg
          end

          #
          status = user.valid? ? 500 : 400

          return res.set_error('', 'Cannot create user', "cannot save to table users", status)
        end

        # update team
        user.team.primary_admin_user_id = user.id
        res_team = user.team.save
        return res.set_error('', 'Cannot save data', "cannot update team.primary_admin_id") if !res_team


        # OK
        res.sysdata[:user_id] = user.id
        res.sysdata[:team_id] = user.team_id

        res.set_data

      rescue => e
        return res.set_error_exception("Cannot create user", e)
      end

      res
    end



    ### create active user and create his own cluster
=begin
    def self.create_user_active_and_create_cluster(teamname, username, email, pwd, userfields={}, sysdata={})
      res = create_user_active(teamname, username, email, pwd, userfields, sysdata)
      return res if res.error?

      #
      user = User.get_by_username username

      # create cluster
      res_cluster = create_cluster(user)
      return res_cluster if res_cluster.error?

      #
      res
    end
=end


    def self.generate_random_password(pass_length)
      Devise.friendly_token.first(pass_length)
    end

    def self.send_password_sms(user,password=nil)

      pass = password ? password : user.password

      gex_logger.debug("debug_registration", "Sending sms", {user_id: user.id})

      begin
        sns = Aws::SNS::Client.new(
            region: 'us-west-2',
            access_key_id: Rails.application.secrets.aws_access_key_id,
            secret_access_key: Rails.application.secrets.aws_secret_access_key
        )

        sns.publish(
            phone_number: user.phone_number,
            message: I18n.t('sms.welcome', username: user.username, password: pass)
        )

        gex_logger.info("user_sms_sent", "SMS was sent", {phone: user.phone_number})

      rescue Aws::SNS::Errors::ServiceError => e
        # rescues all errors returned by Amazon Simple Notification Service
        gex_logger.error("registration_error", "Cannot send sms", {e: e.message, username: user.username})
        return false
      rescue Exception => e
        gex_logger.exception("Cannot send SMS", e, {username: user.username})
        return false
      end

      true

    end


    def self.check_phone_number phone_number
      #pn = Phoner::Phone.parse(phone_number)
      #area_code = pn.format("%A")
      #allowed_countries_str = Gexcore::OptionService.get_option('registration_countries').data['registration_countries']
      allowed_countries_str = Gexcore::Settings.get_option('registration_countries', [])
      allowed_countries = (JSON.parse(allowed_countries_str) rescue [])
      allowed_countries.select{|x| Phonelib.valid_for_country? phone_number, x }.length > 0
    end







    ### create new not-verified user and create team, make user superadmin of the team
    def self.create_user_not_verified(user, sysdata={}, registration_options={})
      res = Response.new
      token = ''

      begin
        #
        token = TokenGenerator.generate_verification_token
        user.confirmation_token = token
        user.confirmed_at = nil
        user.status = User::STATUS_NOT_VERIFIED
        user.registration_options = registration_options.to_json

        #
        res.sysdata[:token] = token

        #
        user.group_id = Group.group_superadmin.id

        # team
        user.team.uid = Gexcore::TokenGenerator.generate_team_uid
        user.team.status = user.status


        #
        res_user = user.save

        if !res_user
          # rollback - in future. if external Identity provider

          # errors
          user.errors.full_messages.each do |msg|
            res.add_error_message msg
          end

          #
          status = user.valid? ? 500 : 400

          return res.set_error('user_create_error', '', "cannot save to table users", status)
        end

        # update team
        user.team.primary_admin_user_id = user.id
        res_team = user.team.save
        return res.set_error('user_create_error', '', "cannot update team.primary_admin_id") if !res_team


        # OK
        res.sysdata[:user_id] = user.id
        res.sysdata[:username] = user.username
        res.sysdata[:team_id] = user.team_id

        res.set_data

      rescue => e
        return res.set_error_exception("Cannot create user", e)
      end


      #
      user.reload
      res.sysdata[:user_id] = user.id

      # email
      UsersMailer.verification_email(user.email, token).deliver_later

      #
      res
    end





    ### create active user and add him to existing team

    def self.create_user_active_in_team(user, team_id, sysdata={}, is_admin_mode=false, is_test_mode=false)
      begin
        res = Response.new

        #
        team = Team.find(team_id)

        #
        user.status = User::STATUS_ACTIVE
        user.confirmation_token = ''
        user.confirmed_at = Time.now.utc

        user.team_id = team.id
        user.group_id = Group.group_user.id

        # phone
        if user.phone_number
          if !is_test_mode
            user.validate_phone

            #if !user.valid?
            #  raise 'Invalid phone'
            # end
          end
        end

        # country
        if is_test_mode
          user.country = Gexcore::Settings.TEST_USER_COUNTRY
        end

        # pwd
        if is_test_mode
          if is_admin_mode
            # do nothing - pwd should be provided
          else
            user.password = Gexcore::Settings.TEST_USER_PWD
          end
        else
          # generate password
          user.password = generate_random_password(8)
        end



        # do not send confirmation email from devise
        user.skip_confirmation!

        res_user = user.save

        if !res_user
          # rollback.

          # errors
          user.errors.full_messages.each do |msg|
            res.add_error_message msg
          end

          #
          status = user.valid? ? 500 : 400

          return res.set_error('', 'Cannot create user', "cannot save to table users", status)
        end

        # OK
        res.sysdata[:user_id] = user.id
        res.sysdata[:team_id] = user.team_id

        res.set_data

      rescue => e
        return res.set_error_exception("Cannot create user", e)
      end

      #
      user.reload


      # email
      UsersMailer.welcome_email(user.email).deliver_later

      #
      res
    end



    ###
    def self.create_user_active_and_add_share(user, cluster_id, sysdata={}, is_admin_mode=false, is_test_mode=false)
      # create user
      res_user = create_user_active(user, sysdata, {}, is_admin_mode, is_test_mode)
      return res_user if res_user.error?

      # reload user
      user = User.get_by_username user.username


      # activate && send SMS or NOT

      is_phone_valid = check_phone_number(user.phone_number)

      to_activate = is_admin_mode || is_test_mode || is_phone_valid

      if to_activate
        # todo - fix
        #UsersMailer.phone_verification_email(user.email).deliver_later
      end


      pwd = generate_random_password(10)
      user.password = pwd
      user.save

      #
      to_send_sms = !is_admin_mode && !is_test_mode && is_phone_valid

      if to_send_sms
        res_sms = send_password_sms(user,pwd)

        if res_sms
          set_sms_sent_field(user)
        end
      end

      # bad phone
      if !to_activate && !to_send_sms
        UsersMailer.registration_email(user.email).deliver_later
      end


      # email
      #UsersMailer.welcome_email(user.email).deliver_later

      # create cluster
      #Gexcore::Clusters::Service.create_cluster(user, sysdata)


      # create share
      cluster = Cluster.find(cluster_id)

      res_share = Gexcore::Shares::Service.cluster_create_share(cluster, user)
      return res_share if res_share.error?

      #
      res_user
    end



    ### create user from invitation token

    def self.create_user_with_invitation_token(token, user, sysdata={}, is_admin_mode=false, is_test_mode=false)
      # check token
      invitation = Gexcore::InvitationsService.find_invitation_by_token(token)
      res_valid = Gexcore::InvitationsService.validate_token(token, invitation.invitation_type)
      return res_valid if res_valid.error?

      # email should be the same as in invitation
      if user.email!=invitation.to_email
        return Response.res_error('', 'Use email from invitation', "email should be the same as in invitation, invitation: #{invitation.to_email}, new email: #{user.email}", 400)
      end


      # create user
      if invitation.invitation_type==Invitation::TYPE_MEMBER
        res_user = create_user_active_in_team(user, invitation.team_id, sysdata, is_admin_mode, is_test_mode)
      elsif invitation.invitation_type==Invitation::TYPE_SHARE
        res_user = create_user_active_and_add_share(user, invitation.cluster_id, sysdata, is_admin_mode, is_test_mode)
      end

      return res_user if res_user.error?

      # update user.invitation_id
      user = User.get_by_email user.email
      user.invitation_id = invitation.id
      user.save

      # set invitation status
      res_activated = invitation.make_accepted!

      if !res_activated
        gex_logger.error('', 'Cannot activate invitation', {invitation_uid: invitation.uid})
      end

      # expire other invitations
      Invitation.where('uid != ?', invitation.uid).where(to_email: invitation.to_email).update_all(status: Invitation::STATUS_EXPIRED)

      #
      res_user
    end



    ###
    def self.verify_user_by_token(token)
      res = verify_user(token)

      if res.success?
        # emails
        user = User.get_by_username(res.data[:user][:username])

        # welcome email
        UsersMailer.welcome_email(user.email).deliver_later
      end

      res
    end

    ### verify - core method
    def self.verify_user(token)
      res = Response.new
      res.sysdata[:user_id] = nil
      res.sysdata[:username] = nil
      res.sysdata[:email] = nil

      # check input
      return res.set_error('', 'Empty token', 'Empty token', 400) if token.nil? || token.blank?

      begin
        # check token exists
        user = User.where(:confirmation_token=>token).first

        return res.set_error('', 'Invalid token', 'Invalid token', 403) if !user

        #
        res.sysdata[:user_id] = user.id
        res.sysdata[:username] = user.username
        res.sysdata[:email] = user.email

        #
        return res.set_error('', 'Token was already used', 'Token was already used', 403) if user.verified?


=begin
        # todo aws: remove from here
        # create cluster
        cluster_options = Gexcore::Clusters::Service.build_cluster_options_from_user(user)
        res_cluster = Gexcore::Clusters::Service.create_cluster(user, {}, cluster_options)

        gex_logger.debug('cluster_create_result', 'create_cluster RESULT', {user_id: user.id, res: res_cluster.inspect})

        return res_cluster.set_sysdata(res.sysdata) if res_cluster.error?
=end
        #
        user.reload

        # verify user
        res_verify = user.verify!
        return res.set_error('user_verify_error', 'Cannot update data', "cannot verify in DB", {user_id: user.id}) if !res_verify

        # activate team
        team = user.team
        if team.primary_admin_user_id == user.id
          team.activate!
        end


        # OK
        return res.set_data(
            {
                team: {
                    id: team.uid,
                    name: team.name
                },
                user: {
                    username: user.username
                }
            }
        )

      rescue => e
        return res.set_error_exception("Cannot verify user", e)
      end


      return res
    end



    def self.verify_user_by_admin(user)
      res = Response.new

      begin
        pwd = generate_random_password(10)
        user.password = pwd

        user.verify!

        res_sms = send_password_sms(user,pwd)

        if res_sms
          set_sms_sent_field(user)
        end

        res_user = user.save

        if !res_user
          # errors
          user.errors.full_messages.each do |msg|
            res.add_error_message msg
          end
          #
          status = user.valid? ? 500 : 400

          return res.set_error('', 'Cannot verify user', "cannot save to table users", status)
        end

        # OK
        res.sysdata[:user_id] = user.id
        res.sysdata[:team_id] = user.team_id

        res.set_data

      rescue => e
        return res.set_error_exception("Cannot verify user", e)
      end

      #
      user.reload

      res

    end


    ### generate random user
    def self.generate_random_user(opts={})
      require 'faker'
      I18n.reload!
      Faker::Config.locale = 'en-US'

      row = User.new

      username = generate_username_production
      row.username = username
      row.email = username+'@galacticexchange.io'

      row.firstname = Faker::Name.first_name
      row.lastname = Faker::Name.last_name

      #row.password = Gexcore::Settings.TEST_USER_PWD
      row.password = 'gex'+Gexcore::Common.random_string_digits(5)


      row.build_team
      row.team.name = username

      # pwd
      row.country = Gexcore::Settings.TEST_USER_COUNTRY
      row.phone_number = Gexcore::Settings.TEST_PHONE_NUMBER

      row
    end

    def self.generate_username_production
      t = Time.now.utc

      dy = t.yday.to_s

      if Rails.env.production?
        dy = "demo"+dy
      else
        dy = "t"+dy
      end

      # get first available
      row_last = User.where("username REGEXP '^#{dy}([a-z]+)$'").order("id desc").first

      letter = 'a'
      if row_last
        u = row_last.username
        u =~ /^#{dy}([a-z]+)$/
        last_letter = $1
        letter = last_letter.next
      end

      "#{dy}#{letter}"
    end

    # add sms date sent to user table in DB
    def self.set_sms_sent_field(user)
      user.sms_was_sent = Time.now.utc
      res_user = user.save
      #
      if !res_user
        gex_logger.error('', 'Cannot update sms_was_sent field for user', {username: user.username})
      end
      #
      res_user
    end

  end
end
