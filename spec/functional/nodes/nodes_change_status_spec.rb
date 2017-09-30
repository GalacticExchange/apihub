RSpec.describe "Node change status", :type => :request do


  describe 'change status' do
    before :each do



    end

    it 'set event' do
      t_transitions_available = {
          :installing => [:installed, :install_error],
          :installed => [:starting],

          :active => [:stopping, :restarting, :start_error],

          :uninstalling => [:uninstalled, :uninstall_error],
          :removing => [:removed, :remove_error],

          :starting => [:active, :start_error],
          :start_error => [:starting, :stopping, :restarting],

          :stopping => [:stopped, :stop_error],
          :stopped => [:starting, :restarting],
          :stop_error => [:restarting, :starting, :stopping],

          :restarting => [:active, :restart_error],
          :restart_error => [:starting, :restarting, :stopping],

      }

      events = Node.aasm.events
      events.each do |event|
        event.transitions.each do |t|
          next if t.from.nil?

          expect(t_transitions_available[t.from]).to include(t.to)
        end
      end


    end

  end

end
