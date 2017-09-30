module ClusterStatus
  extend ActiveSupport::Concern



  included do
    enum status: {
        active: 1,

        installing: 2,
        installed: 3,
        install_error: 4,

        removing: 5,
        removed: 6,
        remove_error: 7,

        uninstalling: 8,
        uninstalled: 9,
        uninstall_error: 10

    }



    aasm :column => :status, :enum => true, :whiny_transitions => false, :no_direct_assignment => true do
      state :installing, :initial=>true
      state :installed
      state :install_error
      state :active
      state :removed
      state :removing
      state :remove_error
      state :uninstalled
      state :uninstalling
      state :uninstall_error

      after_all_transitions :log_status_change



      # install
      event :finish_install do
        after do
          #
          Gexcore::Clusters::Service.log_installed(self)

          #
          Gexcore::Clusters::Service.do_after_installed(self)
        end

        #
        transitions :from => :installing, :to => :installed
      end

      event :activate do
        after do
          Gexcore::Clusters::Service.email_after_cluster_installed(self)
        end

        transitions :to => :active
      end

      event :set_install_error do
        after do
          #
          Gexcore::Clusters::Service.log_install_error(self)
        end

        transitions :to => :install_error
      end


      # uninstall
      event :begin_uninstall do
        after do
          #NodesFixStatusWorker.perform_in(1.hour, self.id, 'uninstalling', 'uninstall_error')

          Gexcore::Clusters::Service.do_after_begin_uninstall(self)
        end

        transitions :to => :uninstalling
      end

      event :finish_uninstall do
        after do
          Gexcore::Clusters::Service.do_after_uninstalled(self)
        end

        transitions :from=>:uninstalling, :to => :uninstalled
      end

      event :set_uninstall_error do
        after do
          Gexcore::GexLogger.error('cluster_uninstall_error', 'Cluster uninstall error', {cluster_id: self.id})
        end

        transitions :from=>:uninstalling, :to => :uninstall_error
      end



      # remove
      event :begin_remove do
        after do
          #NodesFixStatusWorker.perform_in(1.hour, self.id, 'removing', 'remove_error')
        end

        transitions :to => :removing
      end

      event :finish_remove do
        transitions :from=>:removing, :to => :removed
      end

      event :set_remove_error do
        transitions :from=>:removing, :to => :remove_error
      end



    end

  end

  def log_status_change
    Gexcore::Clusters::Service.log_status_change(self)
  end


end
