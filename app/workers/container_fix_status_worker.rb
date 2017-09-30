class ContainerFixStatusWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :clusters, :retry => false

  def perform(container_id, old_status, new_status, env={})
    # set env
    Gexcore::BaseService.set_env env

    #
    Gexcore::Containers::Service.fix_status(container_id, old_status, new_status)

    return true
  end
end
