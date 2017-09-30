module Gexcore::AppHadoop
  class Provision < Gexcore::BaseService

    ### provision master node

    def self.provision_master_create_cluster_run_script_enqueue(application_id)
      AppHadoopProvisionMasterCreateClusterWorker.perform_async(application_id, get_env)

      return Response.res_data
    end

    def self.provision_master_create_cluster_run_script(application_id)
      res = Response.new

      #
      app = ClusterApplication.find(application_id)
      cluster = app.cluster

      #
      res.sysdata[:cluster_id] = cluster.id

      #
      res_provision = Gexcore::Clusters::Provision.provision_master_create_cluster(app)

      if res_provision.error?
        #raise ActiveRecord::Rollback
        #raise "Ansible error"

        cluster.set_install_error!

        return res.set_error('provision_error', 'Error provisioning master')
      end

      # todo: wait for the notify

      res_app_status = app.finish_install!
      res_install = cluster.finish_install!

      res.set_data
    end
  end
end

