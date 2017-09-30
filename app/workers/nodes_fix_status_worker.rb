class NodesFixStatusWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :clusters, :retry => false

  def perform(node_id, old_status, new_status, env={})
    # set env
    Gexcore::BaseService.set_env env

    #
    Gexcore::Nodes::Service.fix_node_status(node_id, old_status, new_status)

    return true
  end
end
