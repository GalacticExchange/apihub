module ApplicationStatus
  extend ActiveSupport::Concern

  included do
    include AASM

    ### status
    enum status: {
        not_installed: 0,
        active: 1,

        installing: 2,
        installed: 3,
        install_error: 4,


        removing: 7,
        removed: 8,
        remove_error: 9,

        uninstalling: 10,
        uninstalled: 11,
        uninstall_error: 12,

    }



    ### AASM

    aasm :column => :status, :enum => true, :whiny_transitions => false, :no_direct_assignment => true do
      state :not_installed, :initial=>true
      state :active

      state :installing
      state :installed
      state :install_error

      state :removing
      state :removed
      state :remove_error

      state :uninstalling
      state :uninstalled
      state :uninstall_error


      # install
      event :begin_install do
        transitions :from => :not_installed, :to => :installing
      end


      # active
      event :set_active do
        before do
          Gexcore::Applications::Service.do_before_activated(self)
        end

        transitions :to => :active
      end


      # install
      event :finish_install do
        before do
          Gexcore::Applications::Service.do_before_installed(self)
        end
        after do
          Gexcore::Applications::Service.do_after_installed(self)
        end

        transitions :from => :installing, :to => :installed
      end

      event :set_install_error do
        before do
          Gexcore::Applications::Service.do_before_install_error(self)
        end

        after do
          Gexcore::GexLogger.error('application_install_error', 'Application install error', {application_id: self.uid})
        end

        transitions :from=>:installing, :to => :install_error
      end


      # uninstall
      event :begin_uninstall do
        #after do
          #NodesFixStatusWorker.perform_in(1.hour, self.id, 'uninstalling', 'uninstall_error')
        #end

        transitions :to => :uninstalling
      end

      event :finish_uninstall do
        after do
          Gexcore::Applications::Service.do_after_uninstalled(self)
        end

        transitions :from=>:uninstalling, :to => :uninstalled
      end

      event :set_uninstall_error do
        after do
          Gexcore::GexLogger.error('app_uninstall_error', 'App uninstall error', {application_id: self.id})

          Gexcore::Applications::Service.uninstall_error_application(self)
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

end
