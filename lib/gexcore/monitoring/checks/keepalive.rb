module Gexcore::Monitoring::Checks

  class Keepalive < ::Gexcore::Monitoring::Checks::Result

    ### state - performance/keepalive state
    STATE_RUNNING = 1
    STATE_DISCONNECTED = 2

    STATE_NAMES = {
        STATE_RUNNING => 'running',
        STATE_DISCONNECTED=>'disconnected'
    }



    ### helpers for state
    def self.get_state_name(state_id)
      return STATE_NAMES[state_id]
    end


    # build result

    def build_from_data(data, check_info, env={})
      @value = self.class.get_value_from_data(data, env)
      @passed = @value == STATE_RUNNING

    end


    # get value from data

    def self.get_value_from_data(data, env={})
      if data.nil?
        return STATE_DISCONNECTED
      end

      # keepalive sent - ok
      status = data['status'].to_i
      if status==0
        v = STATE_RUNNING
      else
        v = STATE_DISCONNECTED
      end

      v
    end

  end
end


