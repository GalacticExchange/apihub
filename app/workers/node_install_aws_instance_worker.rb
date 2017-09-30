class NodeInstallAwsInstanceWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :clusters, :retry => false

  def perform(node_id, env={})
    # set env
    Gexcore::BaseService.set_env env


    #
    Gexcore::Nodes::Aws::Provision.create_node_aws_instance(node_id)


    return true
  end
end
