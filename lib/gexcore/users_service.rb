module Gexcore
  class UsersService < BaseService

    def self.get_fields_data_from_params(p)
      res = {}


      # collect from params
      mapping = User::FIELDS_COMMON_MAPPING.invert

      (User::FIELDS_COMMON+mapping.keys).each do |f|
        name = f.to_sym
        next unless p.has_key? name
        res[f.to_sym] = p[name]
      end

      # fix names
      mapping.each do |f_new, f|
        name_new = f_new.to_sym
        name = f.to_sym
        # name_new => name
        next unless res.has_key? name_new
        res[name.to_sym] = res.delete(name_new.to_sym)
      end

      res
    end



    ### user info, password

    def self.get_user_info(username)
      #
      user = User.get_by_username(username)

      # user not exists
      return Response.res_error_badinput("", 'user not found', 'user not found or user was deleted') if user.nil? || user.status == User::STATUS_DELETED

      # hash
      user_hash = user.to_hash_public
      #role = Group.find(user.group_id_in_cluster)
      user_hash[:role] = user.group.name

      Response.res_data({user: user_hash})
    end

    def self.update_user_info(username, fields_data)
      res = Response.new

      #
      user = User.get_by_username(username)

      #
      res.sysdata[:user_id] = user.id

      # user update
      fields_data.each do |f, v|
        user[f] = v
      end

      #
      res_save = user.save

      if !res_save
        res.sysdata[:username] = user.username
        res.sysdata[:fields] = fields_data

        return res.set_error("", "Cannot update user", 'cannot save to users')
      end


      res.set_data
    end

    # change password
    def self.set_password_by_old_password(username, oldpwd, pwd)
      res = Response.new

      user = User.get_by_username(username)
      return res.set_error_badinput('','user not found', "user not found: #{username}") if user.nil?

      # check if old password is correct
      if !user.valid_password?(oldpwd)
        return res.set_error_badinput('','Incorrect current password', "current password invalid")
      end

      # DB
      user.password = pwd
      user.password_confirmation = pwd
      res_user = user.save
      return res.set_error("", 'cannot update user', 'cannot update in DB') if !res_user

      res.set_data
    end


    # change user password by admin
    def self.set_password_by_admin(master_user, victim_username, pwd)
      res = Response.new
      res.sysdata[:username] = victim_username

      # find master_user
      if master_user.is_a? String
        master_user = User.get_by_username(master_user)
      end
      return res.set_error_badinput('','user not found', "user not found: #{master_username}") if master_user.nil?

      #
      res.sysdata[:user_id] = master_user.id

      # find victim
      user = User.get_by_username(victim_username)
      return res.set_error_badinput('','user not found', "user not found: #{victim_username}") if user.nil?

      # check permissions
      if !(master_user.can? :user_password_change, user)
        return res.set_error_forbidden('','you cannot change password this user', 'you cannot change password this user. you have not permissions')
      end

      # DB
      user.password = pwd
      user.password_confirmation = pwd
      res_user = user.save
      return res.set_error("", 'cannot update user', 'cannot update in DB') if !res_user

      res.set_data
    end

    # change user password from admin area
    def self.set_password_from_adminarea(victim_user, pwd)
      res = Response.new

      # victim
      return res.set_error_badinput('','user not found', "user not found: #{victim_username}") if victim_user.nil?

      # DB
      victim_user.password = pwd
      victim_user.password_confirmation = pwd
      res_user = victim_user.save
      return res.set_error("", 'cannot update user', 'cannot update in DB') if !res_user

      res.set_data
    end

    def self.set_password_by_token(token, password)
      res = Response.new

      #
      db_token = Devise.token_generator.digest(User, :reset_password_token, token)
      user = User.where(reset_password_token: db_token).first

      # check user exist
      return res.set_error_badinput("", 'Token invalid', "token not found") if user.nil?

      #
      res.sysdata[:user_id] = user.id


      # DB
      user.password = password
      user.password_confirmation = password
      res_user = user.save
      return res.set_error("", 'cannot update user', 'cannot update in DB').set_sysdata(sysdata) if !res_user

      res.set_data
    end


    ### send resetpassword link

    def self.send_resetpassword_link(username)
      # find user from DB
      user = User.get_by_username_or_email(username)

      # check to user existing
      return Response.res_error_badinput("", 'user not found', 'user not found') if user.nil?

      # set password token using Devise
      token = Gexcore::TokenGenerator.generate_password_uid
      user.reset_password_token = Devise.token_generator.digest(User, :reset_password_token, token)
      user.reset_password_sent_at = Time.now.utc
      res_save = user.save

      #return Response.res_error("", 'Cannot update data in DB', 'cannot update in DB') if !res_save

      # send resetlink email
      mail = UsersMailer.resetpassword_email(user.id, token)
      mail.deliver_later

      Response.res_data
    end

    def self.get_link_resetpassword(user, token)
      make_hub_link "resetpassword/#{token}"
    end


    ### delete user

    def self.delete_user_by_admin(username, master_user)
      res = Response.new

      res.sysdata[:user_id] = master_user.id
      res.sysdata[:username] = username

      #
      return res.set_error_badinput('','user not found', "bad user") if master_user.nil?

      # log
      log_data = {username: username}
      #Apiservice::LoggerUserAction.add('user_delete', master_user.id, log_data)


      # user
      if username.is_a? String
        victim = User.get_by_username(username)
      else
        victim = username
      end

      return res.set_error_badinput('','user not found', "user not found: #{username}") if victim.nil?


      # check permissions
      if !(master_user.can? :user_del, victim)
        return res.set_error_forbidden('','you cannot delete this user', 'you cannot delete this user')
      end

      #
      res_delete = delete_user_in_team(victim)
      return res_delete if res_delete.error?

      #
      res.set_data
    end

    def self.delete_user_in_team(user)
      #
      begin
        old_status = user.status

        #
        user.status = User::STATUS_PENDING_DELETE
        user.save!

        #
        delete_user_data(user)

        #
        user.status = User::STATUS_DELETED
        user.save!

      rescue =>e
        return Response.res_error('', 'Cannot delete user', "delete user. exception: #{e.inspect}")
      end

      Response.res_data
    end


    def self.delete_user_data(user)
      ClusterAccess.where(user_id: user.id).delete_all
      Invitation.where(from_user_id: user.id).delete_all

    end


    ### user list

    def self.get_users_in_team(user, format='hash')

      # team
      team = Team.find(user.team_id)

      # cluster not exists
      return Response.res_error_badinput("", 'team not found', "team not found for user id #{user.id}") if team.nil?

=begin
      # check permissions
      if !(user.can?(:get_list_of_users, cluster))
        return Response.res_error_forbidden('','you cannot see the users list', 'you cannot see the users list')
      end
=end
      #
      rows = list_users_in_team team.id

      #
      if format=='hash'
        data = rows.map{|user| user.to_hash }
        users = {users: data}
      else
        users = rows
      end

      Response.res_data(users)
    end

    def self.list_users_in_team(team_id)
      User.w_not_deleted.where(:team_id => team_id).order("id ASC").all
    end


    #### change role for user

    def self.set_role_by_admin(master_user, team, victim_username, role_name_or_obj)
      res = Response.new
      res.sysdata[:user_id] = master_user.id
      res.sysdata[:username] = victim_username

      # input
      # victim user
      if victim_username.is_a? String
        victim = User.get_by_username(victim_username)
      else
        victim = victim_username
      end

      # check to victim user existing
      return res.set_error_badinput("", 'user not found', 'user not found') if victim.nil?


      # find team
      if team.is_a? Integer
        team = Team.find(team)
      end

      return res.set_error_badinput("", 'Team not found', 'team not found') if team.nil?


      # role
      if role_name_or_obj.is_a? String
        role = Group.get_by_name role_name_or_obj
      else
        role = role_name_or_obj
      end

      # check permissions
      if !(master_user.can? :change_role, [victim, role.id])
        return res.set_error_forbidden('','No permissions to change role', 'no permissions. you cannot change the role')
      end

      # do it
      res_role = set_user_role_in_team(victim, role.id)

      return res.set_error('', 'Cannot update data', "cannot update in table users_groups") if !res_role

      #
      res.sysdata[:role_id] = role.id

      # OK
      return res.set_data
    end



    def self.set_user_role_in_team(user, group_id)
      user.group_id = group_id
      user.save
    end


  end
end
