class NodeUninstallProvisionMasterWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :clusters, :retry => false

  def perform(node_id, env={})
    # set env
    Gexcore::BaseService.set_env env

    #
    Gexcore::Nodes::Provision.provision_master_uninstall_node(node_id, env)


    return true
  end
end
