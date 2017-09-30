class ClusterDeleteAllWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :clusters, :retry => false
  def perform(cluster_id, node_ids, env={})
    # set env
    Gexcore::BaseService.set_env env

    #
    Gexcore::Clusters::Service.delete_cluster_all(cluster_id, node_ids, env)


    return true
  end
end
