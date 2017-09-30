module ContainerStatus
  extend ActiveSupport::Concern

  included do
    include AASM

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



      ### callbacks
      after_all_transitions :log_status_change



      ### events

      event :begin_install do
        transitions :to => :installing
      end

      event :finish_install do
        transitions :from=> :installing, :to => :installed

        after do
          #
          Gexcore::Containers::Service.do_after_installed(self)
        end
      end


      event :set_active do
        transitions :to => :active
      end


      event :set_install_error do
        transitions :from=>:installing, :to => :install_error
      end



      event :finish_install do
        transitions :from => :installing, :to => :installed

        after do
          Gexcore::Containers::Service.do_after_installed(self)
        end
      end




      # uninstall

      event :begin_uninstall do
        transitions :to => :uninstalling

        after do

        end
      end

      event :finish_uninstall do
        transitions :from=>:uninstalling, :to => :uninstalled

        after do

        end
      end

      event :set_uninstall_error do
        after do
          Gexcore::GexLogger.error('container_uninstall_error', 'Container uninstall error', {container_id: self.id})
        end

        transitions :from=>:uninstalling, :to => :uninstall_error
      end


      # remove
      event :set_removed do
        transitions :to => :removed
      end

      event :begin_remove do
        transitions :to => :removing
      end

      event :finish_remove do
        transitions :from=>:removing, :to => :removed
      end

      event :set_remove_error do
        transitions :from=>:removing, :to => :remove_error
      end

      # start
      event :begin_start do
        after do
          ContainerFixStatusWorker.perform_in(30.minutes, self.id, 'starting', 'start_error')
        end

        transitions :from=>[:installed, :stopped, :start_error, :stop_error, :restart_error], :to => :starting
      end

      event :finish_start do
        transitions :from=>:starting, :to => :active

        after do
          Gexcore::Containers::Service.do_after_started(self)
        end
      end

=begin
        event :finish_start do
          transitions :from=>[:installed, :starting], :to => :active
        end
=end


      event :set_start_error do
        transitions :from=>[:starting, :active], :to => :start_error
      end




      # stop
      event :begin_stop do
        transitions :from=>[:active, :start_error, :stop_error, :restart_error], :to => :stopping

        after do
          ContainerFixStatusWorker.perform_in(30.minutes, self.id, 'stopping', 'stop_error')
        end
      end

      event :finish_stop do
        transitions :from=>:stopping, :to => :stopped
      end

      event :set_stop_error do
        transitions :from=>:stopping, :to => :stop_error
      end

      # restart
      event :begin_restart do
        transitions :from=>[:active, :start_error, :stop_error, :stopped, :restart_error], :to => :restarting

        after do
          ContainerFixStatusWorker.perform_in(30.minutes, self.id, 'restarting', 'restart_error')
        end
      end

      event :finish_restart do
        transitions :from=>:restarting, :to => :active
      end

      event :set_restart_error do
        transitions :from=>[:restarting], :to => :restart_error
      end

    end


    ###


    def log_status_change
      Gexcore::Containers::Service.log_status_change(self)
    end



  end

end
