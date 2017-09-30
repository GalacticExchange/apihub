module Gexcore
  class InvitationsService < BaseService

    #### send invitation

    def self.send_invitation(team_id, email, master_user)
      res = Response.new
      res.sysdata[:user_id] = master_user.id
      res.sysdata[:team_id] = team_id
      res.sysdata[:email] = email

      # input
      return res.set_error_badinput("", 'email is empty', "email is empty: #{email}") if email.nil? || email.blank?

      # team
      if team_id.is_a? Integer
        team = Team.find(team_id)
      else
        team = team_id
      end


      # find victim user
      victim = User.get_by_email(email)

      # check to victim user doesn't exist
      return res.set_error_badinput("", 'User exists in your team', 'User exists in the team') if victim

      return res.set_error_badinput("", 'User exists in another team', 'User in another team') if victim && victim.team_id!=team_id

      # check cluster exist
      #return Response.res_error_badinput("", 'cluster not found', 'cluster not found') if cluster.nil?

      # check permissions
      if !(master_user.can? :send_inv, team)
        return res.set_error_forbidden('','You cannot send invitation', 'you cannot send invitation')
      end


      # log
      log_data = {team_id: team.id, email: email}
      #LogUserAction.add_message('user_invite', master_user.id, log_data)

      # add invitations
      invitation = Invitation.add_invite(email, master_user.id, team.id)


      # send invitation email
      UsersMailer.invitation_email(invitation.id).deliver_later

      #
      res.set_data
    end


    def self.get_link(invitation_uid)
      make_hub_link "inviteaccept/#{invitation_uid}"
    end

    #
    def self.find_invitation_by_token(token)
      Invitation.get_by_uid(token)
    end

    def self.find_not_activated_invitation_by_token(token)
      token ||= ''
      return nil if token.blank?

      row = Invitation.where_not_activated.where(uid: token).first

      row
    end

    #### send share invitation

    def self.send_share_invitation(master_user, email, cluster_id)
      res = Response.new

      # cluster
      cluster = Cluster.get_by_id(cluster_id)

      # check cluster exist
      return res.set_error_badinput("", 'cluster not found', 'cluster not found') if cluster.nil?

      #
      res.sysdata[:email] = email
      res.sysdata[:cluster_id] = cluster_id


      # check permissions
      if !(master_user.can? :share_send, cluster)
        return res.set_error_forbidden('','you cannot create share', 'you cannot create share')
      end

      #
      victim = User.get_by_email(email)

      # check: victim user doesn't exist
      return res.set_error_badinput("", 'user exists', 'user exists') if victim

      # log
      log_data = {cluster_id: cluster.id, email: email}
      #LoggerUserAction.add('cluster_share', master_user.id, log_data)


      # add invitations
      invitation = Invitation.add_share(email, master_user.id, cluster.id)

      # send email
      UsersMailer.share_invitation_email(invitation.id).deliver_later

      #
      res.set_data
    end

    def self.get_link_share(invitation_uid)
      make_hub_link "inviteaccept/#{invitation_uid}"
    end

    #
    def self.validate_token(token, type=nil)
      # not found in DB
      w = {uid: token}
      w[:invitation_type] = type unless type.nil?

      row = Invitation.where(w).first
      return Response.res_error('token_notfound', 'Token not found', 'token not found', 400) if row.nil?

      # already activated
      return Response.res_error('token_used', 'Token already used', 'token used', 400) if row.activated?

      # bad status
      return Response.res_error('token_expired', 'Token has been expired', 'token expired', 400) if row.expired? || row.deleted?

      return Response.res_data
    end



    ### invitations list

    # format = 'hash' | 'rows'
    def self.get_invitations_in_team(user, team_id, format='hash')
      # cluster
      team = Team.find(team_id)

      # team not exist
      return Response.res_error_badinput("", 'team not found', "team not found for id #{team_id}") if team.nil?

      # check permissions
      if !(user.can? :get_list_of_invitations_team, team)
        return Response.res_error_forbidden('','you cannot see the invitations list', 'you cannot see the invitations list. access denied')
      end

      # get data
      invitations = list_invitations_in_team(team_id)

      #
      if format=='hash'
        data = invitations.map{|invitation| invitation.to_hash }
        invitations = {invitations: data}
      else
        data = invitations
      end


      Response.res_data(invitations)
    end

    def self.list_invitations_in_team(team_id)#, opt={})
      Invitation.where(:team_id => team_id, :status => Invitation::STATUS_NOT_ACTIVATED, :invitation_type => Invitation::TYPE_MEMBER).order("id DESC").limit(100).all
    end

    ### share_invitations list

    def self.get_share_invitations_in_cluster(user, cluster_id)
      # cluster
      cluster = Cluster.find(cluster_id)

      # cluster not exists
      return Response.res_error_badinput("", 'cluster not found', "cluster not found for id #{cluster_id}") if cluster.nil?

      # check permissions
      if !(user.can? :get_list_of_invitations, cluster)
        return Response.res_error_forbidden('','you cannot see the share_invitations list', 'you cannot see the share_invitations list. access denied')
      end

      share_invitations = Invitation.where(:cluster_id => cluster.id, :status => Invitation::STATUS_NOT_ACTIVATED, :invitation_type => Invitation::TYPE_SHARE).order("id ASC").all

      #
      data = share_invitations.map{|share_invitation| share_invitation.to_hash }

      invitations = {invitations: data}

      Response.res_data(invitations)
    end

    ### share_invitations list

    def self.delete_invitation(user, invitation_id)
      #
      res = Response.new

      # team
      team = Team.find(user.team_id)

      # team not exists
      return res.set_error_badinput("", 'team not found', "team not found for #{user.username}") if team.nil?

      # invitation
      invitation = Invitation.find(invitation_id)
      # invitation not exists
      return res.set_error_badinput("", 'invitation not found', "invitation not found id #{invitation_id}") if invitation.nil?

      res.sysdata[:to_email] = invitation.to_email

      # check permissions
      if !(user.can? :destroy_invitation, team)
        return res.set_error_forbidden('','you cannot delete the invitation', 'you cannot delete the invitation. access denied')
      end

      # data for invitation
      data = invitation.attributes


      # delete row from invitations
      res_destroy = invitation.destroy
      if !res_destroy || !res_destroy.destroyed?
        return res.set_error_badinput("", 'Error deleting invitation', "invitation not deleted from DB")
      end

      res.set_data
    end

  end
end

