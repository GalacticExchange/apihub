module Gexcore
  class TeamsService < BaseService

    def self.get_fields_data_from_params(p)
      res = {}

      # collect from params
      mapping = Team::FIELDS_COMMON_MAPPING.invert

      (Team::FIELDS_COMMON+mapping.keys).each do |f|
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

    def self.get_team_info(team_id)
      #
      team = Team.find(team_id)

      # user not exists
      return Response.res_error_badinput("", 'team not found', "team not found, id:#{team_id}") if team.nil?

      Response.res_data({team: team.to_hash_with_images})
    end

    def self.update_team_info_by_user(user, teamname, fields_data)
      res = Response.new

      if teamname.is_a?String
        team = Team.get_by_name(teamname)
      else
        team = teamname
      end

      return Response.res_error_badinput("", 'team not found', "team not found") if team.nil?

      if user.is_a?String
        user = User.get_by_username(user)
      else
        user
      end

      return Response.res_error_badinput("", 'user not found', "user not found") if user.nil?

      res.sysdata[:team_id] = team.id

      # check permissions
      if !(user.can? :change_team, team)
        return res.set_error_forbidden('','No permissions to update team', 'no permissions. you cannot change the team')
      end

      res_save = update_team_info(team, fields_data)

      if !res_save
        res.sysdata[:name] = team.name
        res.sysdata[:fields] = fields_data

        return res.set_error("", "Cannot update team", 'cannot save to teams')
      end

      res.set_data
    end

    def self.update_team_info(team, fields_data)

      # team update
      fields_data.each do |f, v|
        team[f] = v
      end

      #
      res_save = team.save
    end

  end
end

