class AppProvisionMasterWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :clusters, :retry => false

  def perform(app_id, env={})
    # set env
    Gexcore::BaseService.set_env env

    #
    #Gexcore::ProvisionService.app_provision_master(app_id, env, method(:"Gexcore::Applications::Service.after_provision_master_install_app"))
    Gexcore::Applications::Provision.app_provision_master(app_id, env, :after_provision_master_install_app)


    return true
  end
end
