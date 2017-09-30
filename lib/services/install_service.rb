module Services
  class InstallService

    def self.create_system_user
      username = 'system'
      teamname = 'galacticexchange'
      email = 'system@galacticexchange.io'

      u = User.where(username: username).first

      p = {teamname: teamname, username: username, email: email,
           password: 'PH_GEX_PASSWD1', password_confirmation: 'PH_GEX_PASSWD1',
           firstname: 'GEX', lastname: 'system'
      }

      team = Team.get_by_name teamname

      if u.nil?
        u = Gexcore::UsersCreationService.build_user_from_params p
        res = Gexcore::UsersCreationService.create_user_active_in_team(u, team.id)

        if !res.success?
          s_errors = res.errors.map{|r| r[:message]}.join(',')
          raise "Cannot create user #{s_errors}"
        end

        #
        #u.reload
        User.uncached do
          u = User.where(username: username).first
        end

      end
    end

    def self.delete_support_user
      # TODO: not finished

      username = 'support'
      u = User.where(username: username).first

      if u
        # TODO: auth first

        #
        res = Gexcore::Api.do_request(:delete, 'users', {:verificationToken=>token})
        if res.error?
          raise 'Cannot delete user'
        end

      end
    end

    def self.create_support_user
      #r = (0...5).map { ('a'..'z').to_a[rand(26)] }.join
      r=''


      username = 'support'+r
      teamname = 'galacticexchange'+r[0..3]
      email = r+'support@galacticexchange.io'

      u = User.where(username: username).first

      p = {teamname: teamname, username: username, email: email,
          password: 'PH_GEX_PASSWD1', password_confirmation: 'PH_GEX_PASSWD1',
          firstname: 'GEX', lastname: 'support'
      }

      if u.nil?
        u = Gexcore::UsersCreationService.build_user_from_params p
        res = Gexcore::UsersCreationService.create_user_active(u)
        #res_save = u.save

        if !res.success?
          s_errors = res.errors.map{|r| r[:message]}.join(',')
          raise "Cannot create user #{s_errors}"
        end

        #
        #u.reload
        User.uncached do
          u = User.where(username: username).first
        end



        # verify
        #res = Gexcore::UsersCreationService.verify_user(u.token)

        if !res
          raise 'Cannot verify user'
        end
      end
    end

  end
end
