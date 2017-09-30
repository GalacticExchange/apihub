class ClusterDeleteWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :clusters, :retry => false
  def perform(cluster_id, env={})
    # set env
    Gexcore::BaseService.set_env env

    #
    Gexcore::Clusters::Service.delete_cluster(cluster_id, env)


    return true
  end
end
