class ClusterAccess < ActiveRecord::Base
  #
  self.table_name = 'cluster_access'

  #
  belongs_to :cluster
  belongs_to :user

  after_save :_after_save

  ### search
  searchable_by_simple_filter



  ### create

  def self.add!(cluster_id, user_id, attr={})
    # find if exists
    row_old = ClusterAccess.where(cluster_id: cluster_id, user_id: user_id).first
    if row_old
      row = row_old
    else
      row = ClusterAccess.new(cluster_id: cluster_id, user_id: user_id)
    end

    row.save!
  end


  def _after_save
    # update data
    Gexcore::ClustersAccessService.redis_update_clusters_access(self.user_id)
  end

  ### access to cluster

  def self.has_access?(cluster_id, user_id)
    ClusterAccess.where(cluster_id: cluster_id, user_id: user_id).exists?
  end

end
