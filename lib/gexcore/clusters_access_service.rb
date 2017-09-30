module Gexcore
  class ClustersAccessService < BaseService
    TTL_CLUSTERS_ACCESS_SECONDS = (30+3)*24*60*60 # 30 days for token + 3 days


    def self.has_access?(user, cluster)
      return true if cluster.team.id == user.team_id

      res_access = ClusterAccess.where(cluster_id: cluster.id, user_id: user.id).exists?
      return true if res_access

      false
    end

    ###

    def self.get_shared_clusters_for_user(user)
      ClusterAccess.where(user_id: user.id).all
    end



    ### service
=begin
    def self.add_cluster_access_to_all_users_in_team(cluster_id)
      if cluster_id.is_a?(Integer)
        cluster = Cluster.get_by_id(cluster_id)
      elsif cluster_id.is_a?(Cluster)
        cluster = cluster_id
      end

      ###
      cluster.team.users.each do |user|
        ClusterAccess.add!(cluster.id, user.id)
      end


      true
    end

    def self.add_cluster_access_to_all_clusters_in_team(user_id)
      if user_id.is_a?(Integer)
        user = User.get_by_id(user_id)
      elsif user_id.is_a?(User)
        user = user_id
      end

      ###
      user.team.clusters.each do |cluster|
        ClusterAccess.add!(cluster.id, user.id)
      end


      true
    end
=end


    def self.cache_update_cluster_access_after_create_cluster(cluster_id)
      # input
      if cluster_id.is_a?(Integer)
        cluster = Cluster.get_by_id(cluster_id)
      elsif cluster_id.is_a?(Cluster)
        cluster = cluster_id
      end

      # work
      cluster.team.users.each do |user|
        redis_update_clusters_access(user)
      end


      true
    end

    ### redis

    def self.redis_update_clusters_access(user)
      if user.is_a? Integer
        user = User.find(user)
      end

      #
      key = redis_key_clusters_access(user)

      $redis.del key

      ids = []
      ids += user.team.clusters.map(&:id)
      clusters_shared = get_shared_clusters_for_user user
      ids += clusters_shared.map(&:cluster_id)
      ids.each do |cluster_id|
        $redis.hset key, cluster_id, "1"
      end

      # set expiration
      $redis.expire key, TTL_CLUSTERS_ACCESS_SECONDS

      #
      true
    end



    def self.redis_get_clusters_access(user)
      key = redis_key_clusters_access(user)

      $redis.hgetall key
    end

    ### redis helpers

    def self.redis_key_clusters_access(user)
      "#{config.redis_prefix}:auth:#{user.id}:clusters_access"
    end


  end
end

