module Gexcore::Monitoring::Metrics

  class Cpu < ::Gexcore::Monitoring::Metrics::Result



    
    ###
    def get_value_from_output(output)
      v_idle = Gexcore::Monitoring::Checks::Evaluator.parse_counter_line(output, 'cpu.idle', true)
      return nil if v_idle.nil?

      # total - idle
      v = (100 - v_idle.to_f).round(0)

      return v

      ### old - before 2017-mar-1
=begin
      return nil if output.nil?
      return nil if output.keys.empty?

      #
      hash = output[output.keys[0]]

      v = hash.fetch('idle', nil)
      return nil if v.nil?

      # total - idle
      v = (100 - v.to_f).round(0)
      #v = v.to_f.round(2)

      v
=end
    end
    

  end
end

