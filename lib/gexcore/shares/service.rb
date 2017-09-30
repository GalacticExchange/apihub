module Gexcore::Shares

  class Service < Gexcore::BaseService

    ### create share

    def self.create_share_by_admin(master_user, cluster, username)
      res = Response.new
      res.sysdata[:user_id] = master_user.id

      # check cluster exist
      return res.set_error_badinput("", 'cluster not found', 'cluster not found') if cluster.nil?

      #
      res.sysdata[:cluster_id] = cluster.id
      res.sysdata[:team_name] = cluster.team.name
      res.sysdata[:username] = username

      # log
      #gex_logger.debug "share_create_start", 'share create start', {cluster_id: cluster.id, username: username}

      # check permissions
      if !(master_user.can? :share_create, cluster)
        return res.set_error_forbidden('','you cannot create share', 'you cannot create share')
      end

      #
      victim = User.get_by_username(username)
      return res.set_error_badinput("", 'user does not exist', 'user does not exist in DB') if victim.nil?

      # victim should not be in our team
      if victim.team_id==cluster.team_id
        return res.set_error_badinput('','You cannot share to a user from your team', 'cannot create share, user in team')
      end


      # access exist
      if ClusterAccess.has_access?(cluster.id, victim.id)
        return res.set_error_badinput('','Cluster is already shared to this user', 'cannot create share, user already in cluster')
      end


      # log
      #log_data = {email: email}
      #LogAccess.add_message('share_create', master_user.id, cluster.id, log_data)

      # do the work
      res_share = cluster_create_share(cluster, victim)
      return res_share if res_share.error?


      # send confirm email
      UsersMailer.share_create_email(victim.id, cluster.id).deliver_later

      # log
      gex_logger.debug "share_create_finish", 'share create - finish', {cluster_id: cluster.id, username: username}

      #
      res.set_data
    end


    def self.cluster_create_share(cluster, victim)
      ug = nil
      begin
        ug = ClusterAccess.add!(cluster.id, victim.id)
      rescue => e
        return Response.res_error_exception('cannot create share', e)
      end

      Response.res_data
    end



    # list

    def self.get_user_shares_list(user, cluster_id)

      # cluster
      cluster = Cluster.find(cluster_id)

      # cluster not exists
      return Response.res_error_badinput("", 'cluster not found', "cluster not found for id #{cluster_id}") if cluster.nil?

      # check permissions
      if !(user.can? :shares_list, cluster)
        return Response.res_error_forbidden('','you cannot see the share users', 'you cannot see the share users. access denied')
      end

      users_groups = ClusterAccess.where(:cluster_id => cluster.id).order("id ASC").all
      #
      users_ids = users_groups.map{ |row| row.user_id }
      users_obj = User.where(id: users_ids).order("id ASC").all
      users_hash = users_obj.map{|u| u.to_hash_share_user }

      users = {shares: users_hash}

      Response.res_data(users)
    end

    ### cluster shares list for user
    # format => 'hash', '' (array of objects)
    def self.get_clusters_share_list_for_user(user, format='hash')

      rows = Gexcore::Shares::Service.list_clusters_share_for_user(user).w_not_deleted

      #
      cluster_ids = rows.map(&:id)
      nodes_not_del_count = Node.w_not_deleted.where(:cluster_id => cluster_ids).group(:cluster_id).count
      nodes_joined_count = Node.w_joined.where(:cluster_id => cluster_ids).group(:cluster_id).count
      aws_regions = AwsRegion.all

      if format=='hash'
        #rows_hash = rows.map{|r| r.to_hash }
        rows_hash = Gexcore::Clusters::Service.to_hash_with_node_counters(rows, nodes_not_del_count, nodes_joined_count, aws_regions)
        data = {clusters: rows_hash}
      else
        data = rows
      end


      Response.res_data(data)
    end

    def self.list_clusters_share_for_user(user)
      #
      users_groups = ClusterAccess.where(:user_id => user.id).order("id ASC").all

      # todo!!!




      clusters_ids = users_groups.map{ |row| row.cluster_id }
      clusters_obj = Cluster.includes(:team, :hadoop_app, :hadoop_type, :cluster_type).where(id: clusters_ids).order("id ASC").all
    end

    ## share delete

    def self.delete_share_by_admin(user, cluster, username)
      res = Response.new
      res.sysdata[:user_id] = user.id

      # add row in log_system
      gex_logger.debug('share_delete_start', 'delete share - start', {user_id: user.id, victim: username})

=begin
      # team
      team = Team.find(user.team_id)
      # team not exists
      return Response.res_error_badinput("", 'team not found', "team not found for #{user.username}") if team.nil?
=end
      # victim
      victim = User.get_by_username(username)
      # victim not exists
      return res.set_error_badinput("", 'shared user not found', "shared user not found with #{username}") if victim.nil?

      # cluster not exists
      return res.set_error_badinput("", 'cluster not found', "cluster not found") if cluster.nil?

      #
      res.sysdata[:cluster_id] = cluster.id
      res.sysdata[:team_name] = cluster.team.name


      # check permissions
      if !(user.can? :destroy_share, cluster)
        return res.set_error_forbidden('','you cannot delete the share', 'you cannot delete the share. access denied')
      end

      # share find
      share = ClusterAccess.where(cluster_id: cluster.id, user_id: victim.id).first
      # cluster_access not exists
      return res.set_error_badinput("", 'the user does not belong to Cluster', "the user does not belong to Cluster #{cluster.name}") if share.nil?
      # data for share
      data = share.attributes

      # delete row from cluster_access
      res_destroy = share.destroy
      if !res_destroy || !res_destroy.destroyed?
        return res.set_error_badinput("", 'Error deleting share', "share not deleted from DB")
      end

      # log
      gex_logger.debug('debug_share_deleted', 'share deleted', {user_id: user.id, cluster_id: cluster.id, share: data})

      res.set_data
    end


  end
end

