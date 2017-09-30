module ClusterServiceStatus
  extend ActiveSupport::Concern

  included do
    include AASM

    # status
    enum status: {
        active: 1,
        removed: 2,
        installing: 3
    }


    aasm :column => :status, :enum => true, :whiny_transitions => false, :no_direct_assignment => true do
      state :active
      state :removed
      state :installing

      ### events
      event :begin_install do
        transitions :to => :installing
      end

      event :finish_install do
        transitions :from => :installing, :to => :active
      end

      event :set_removed do
        transitions :to => :removed
      end


    end


  end


end
