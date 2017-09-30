class ContainerControlWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :clusters, :retry => false

  def perform(container_id, cmd, env={})
    # set env
    Gexcore::BaseService.set_env env

    #
    Gexcore::Containers::Provision.run_control_command(container_id, cmd, env)


    return true
  end
end
