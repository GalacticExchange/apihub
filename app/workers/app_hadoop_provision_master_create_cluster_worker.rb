class AppHadoopProvisionMasterCreateClusterWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :clusters, :retry => false

  def perform(application_id, env={})
    # set env
    Gexcore::BaseService.set_env env

    #
    Gexcore::AppHadoop::Provision.provision_master_create_cluster_run_script(application_id)

    return true
  end
end
