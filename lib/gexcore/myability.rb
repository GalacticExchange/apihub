module Gexcore
  class Myability
    include CanCan::Ability

    def initialize(user)

      can :cluster_create, Object do
        if [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
          true
        else
          false
        end
      end

      can :manage, Cluster do |cluster|
        if user.team_id == cluster.team_id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        elsif cluster.team_id==user.team_id
          true
        else
          false
        end
      end

      can :cluster_delete, Cluster do |cluster|
        if user.team_id == cluster.team_id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        else
          false
        end
        #([Group.group_superadmin.id].include? user.group_id_in_cluster(cluster.id)) && cluster.primary_admin_user_id==user.id
      end


      can :change_role, Array do |p|
        victim = p[0]
        new_group_id = p[1]

        #
        master_user = user


        # the user role not to superadmin
        if new_group_id == Group.group_superadmin.id
          false
        # user from another team
        elsif victim.team_id != master_user.team_id
          false
        else
          if master_user.group_id == Group.group_superadmin.id
            true if victim.id != master_user.id
          elsif master_user.group_id == Group.group_admin.id
            if [Group.group_superadmin.id, Group.group_admin.id].include?(victim.group_id)
              false
            else
              true
            end
          else
            false
          end

        end
      end

      can :send_inv, Team do |team|
        if user.team_id == team.id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        else
          false
        end
      end

      can :user_del, User do |victim|
        #
        master_user = user

        # cluster id for master user
        master_user_team_id = master_user.team_id
        master_user_group_id = master_user.group_id

        # master user and victim in the same cluster
        if victim.team_id != master_user_team_id || victim.id == master_user.id
          false

        # user cannot delete
        elsif master_user_group_id == Group.group_user.id
          false
        # master user is superadmin or admin
        elsif master_user_group_id == Group.group_superadmin.id
          true
        elsif master_user_group_id == Group.group_admin.id
          if [Group.group_superadmin.id, Group.group_admin.id].include? victim.group_id
            false
          elsif victim.group_id == Group.group_user.id
            true
          end

        # unknown situation
        else
          false
        end
      end

      can :share_create, Cluster do |cluster|
        if user.team_id == cluster.team_id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        else
          false
        end
      end

      can :share_send, Cluster do |cluster|
        if user.team_id == cluster.team_id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        else
          false
        end
      end

      can :shares_list, Cluster do |cluster|
        if user.team_id == cluster.team_id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        else
          false
        end
      end

      can :destroy_share, Cluster do |cluster|
        if user.team_id == cluster.team_id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        else
          false
        end
      end


      can :get_list_of_users, Cluster do |cluster|
        user.team_id == cluster.team_id
      end

      can :get_list_of_invitations, Cluster do |cluster|
        if user.team_id == cluster.team_id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        else
          false
        end
      end

      can :get_list_of_invitations_team, Team do |team|
        if user.team_id == team.id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        else
          false
        end
      end

      can :destroy_invitation, Team do |team|
        if user.team_id == team.id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        else
          false
        end
      end


      can :user_password_change, User do |victim|
        #
        master_user = user

        # cluster id for master user

        # master user and victim in the same team
        if victim.team_id != master_user.team_id
          false
        # user cannot change pwd
        elsif master_user.group_id == Group.group_user.id
          false
          # master user is superadmin or admin
        elsif [Group.group_superadmin.id, Group.group_admin.id].include? master_user.group_id
          # cannot change pwd admin or superadmin
          if [Group.group_user.id, Group.group_admin.id].include? victim.group_id
            true
          elsif victim.group_id == Group.group_superadmin.id
            false
          end

          # unknown situation
        else
          false
        end
      end


      can :view_log, Team do |team|
        if user.team_id == team.id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        else
          false
        end
      end

      can :change_team, Team do |team|
        if user.team_id == team.id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        else
          false
        end
      end


      can :view_clusters_in_team, Team do |team|
        if user.team_id == team.id
          true
        else
          false
        end
      end


      can :view_cluster_info, Cluster do |cluster|
        if user.team_id == cluster.team_id
          true
        elsif ClusterAccess.has_access?(cluster.id, user.id)
          true
        else
          false
        end
      end

      can :view_service_info, Cluster do |cluster|
        if user.team_id == cluster.team_id
          true
        elsif ClusterAccess.has_access?(cluster.id, user.id)
          true
        else
          false
        end
      end

      can :view_node_info, Node do |node|
        if user.team_id == node.cluster.team_id
          true
        elsif ClusterAccess.has_access?(node.cluster.id, user.id)
          true
        else
          false
        end
      end

      can :view_node_logs, Node do |node|
        if user.team_id == node.cluster.team_id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        else
          false
        end
      end

      can :view_cluster_logs, Cluster do |cluster|
        if user.team_id == cluster.team_id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        else
          false
        end
      end


      ### apps
      can :manage, ClusterApplication do |app|
        if user.team_id == app.cluster.team_id
          [Group.group_superadmin.id, Group.group_admin.id].include? user.group_id
        else
          false
        end
      end


      can :view_app_info, ClusterApplication do |app|
        if user.team_id == app.cluster.team_id
          true
        elsif ClusterAccess.has_access?(app.cluster_id, user.id)
          true
        else
          false
        end
      end

    end
  end

end

