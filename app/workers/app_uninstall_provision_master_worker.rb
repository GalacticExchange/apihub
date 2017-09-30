class AppUninstallProvisionMasterWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :clusters, :retry => false
  def perform(application_id, env={})
    # set env
    Gexcore::BaseService.set_env env

    #
    Gexcore::Applications::Provision.app_uninstall_provision_master(application_id, env, :after_provision_master_uninstall_app)


    return true
  end
end
