module NodeStatus
  extend ActiveSupport::Concern


  included do

    include AASM


    ### status, state
    enum status: {
        active: 1,

        installing: 2,
        installed: 3,
        install_error: 4,

        starting: 5,
        start_error: 6,

        removing: 7,
        removed: 8,
        remove_error: 9,

        uninstalling: 10,
        uninstalled: 11,
        uninstall_error: 12,

        stopping: 13,
        stop_error: 14,
        stopped: 15,

        restarting: 16,
        restart_error: 17
    }



    aasm :column => :status, :enum => true, :whiny_transitions => false, :no_direct_assignment => true do
      state :active

      state :installing, :initial=>true
      state :installed
      state :install_error

      state :starting
      state :start_error

      state :restarting
      state :restart_error

      state :stopping
      state :stop_error
      state :stopped

      state :removing
      state :removed
      state :remove_error

      state :uninstalling
      state :uninstalled
      state :uninstall_error

      #
      after_all_transitions :log_status_change
      after_all_transitions :set_status_changed

      # install
      #event :begin_install do
      #  after do
      #    NodesFixStatusWorker.perform_in(1.hour, self.id, 'installing', 'install_error')
      #  end
      #  transitions :from => :installing, :to => :installing
      #end

      event :finish_install do
        after do
          Gexcore::Nodes::Service.do_after_installed(self)
        end

        transitions :from => :installing, :to => :installed
      end

      event :set_install_error do
        after do
          Gexcore::GexLogger.error('node_install_error', 'Node install error', {node_id: self.id})
          Gexcore::Nodes::Service.do_after_install_error(self)
        end

        transitions :from=>:installing, :to => :install_error
      end


      # start
      event :begin_start do
        transitions :from=>[:installed, :stopped, :start_error, :stop_error, :restart_error], :to => :starting

        after do
          Gexcore::Nodes::Service.do_after_begin_start(self)
        end
      end

      event :finish_start do
        transitions :from=>:starting, :to => :active

        after do
          Gexcore::Nodes::Service.do_after_started(self)
        end
      end

      event :set_start_error do
        transitions :from=>[:starting, :active], :to => :start_error

        after do
          Gexcore::Nodes::Service.do_after_start_error(self)
        end
      end


      # stop
      event :begin_stop do
        transitions :from=>[:active, :start_error, :stop_error, :restart_error], :to => :stopping

        after do
          Gexcore::Nodes::Service.do_after_begin_stop(self)
        end

        #transitions :from=>[:active, :start_error], :to => :stopping
      end
      event :finish_stop do
        transitions :from=>:stopping, :to => :stopped

        after do
          Gexcore::Nodes::Service.do_after_stopped(self)
        end
      end

      event :set_stop_error do
        transitions :from=>:stopping, :to => :stop_error

        after do
          Gexcore::Nodes::Service.do_after_stop_error(self)
        end
      end

      # restart
      event :begin_restart do
        after do
          Gexcore::Nodes::Service.do_after_begin_restart(self)
        end

        transitions :from=>[:active, :start_error, :stop_error, :stopped, :restart_error], :to => :restarting
      end
      event :finish_restart do
        after do
          Gexcore::Nodes::Service.do_after_restarted(self)
        end

        transitions :from=>:restarting, :to => :active
      end
      event :set_restart_error do
        after do
          Gexcore::Nodes::Service.do_after_restart_error(self)
        end

        transitions :from=>[:restarting], :to => :restart_error
      end

      # uninstall
      event :begin_uninstall do
        after do
          Gexcore::Nodes::Service.do_after_begin_uninstall(self)
        end

        transitions :to => :uninstalling
      end

      event :finish_uninstall do
        after do
          Gexcore::Nodes::Service.do_after_uninstalled(self)
        end

        transitions :from=>:uninstalling, :to => :uninstalled
      end

      event :set_uninstall_error do
        after do
          Gexcore::GexLogger.error('node_uninstall_error', 'Node uninstall error', {node_id: self.id})
        end

        transitions :from=>:uninstalling, :to => :uninstall_error
      end


      # remove
      event :begin_remove do
        after do
          NodesFixStatusWorker.perform_in(1.hour, self.id, 'removing', 'remove_error')
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

    #
    STATUSES_WORKING = [:installing, :starting, :stopping, :uninstalling, :removing]
    STATUSES_WORKING_MAPPING_ERRORS = {
        :installing=>:install_error,
        :starting=>:start_error, :stopping=>:stop_error,
        :uninstalling=>:uninstall_error,
        :removing=>:remove_error
    }


    # scopes
    scope :w_statuses_working, -> { where(status: STATUSES_WORKING) }


  end

  def log_status_change
    Gexcore::Nodes::Control.log_status_change(self)
  end

  def after_begin_install
    NodesFixStatusWorker.perform_in(1.hour, self.id, 'installing', 'install_error')
    set_status_changed
  end

  def set_status_changed
    Node.set_status_changed(self)
  end

end
