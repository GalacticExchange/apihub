module Gexcore::Monitoring::Metrics

  class Memory < ::Gexcore::Monitoring::Metrics::Result



    
    ###
    def get_value_from_output(output)
      return nil if output.nil?
      return nil if output.keys.empty?

      #
      hash = output[output.keys[0]]

      v = hash.fetch('freeWOBuffersCaches', nil)
      return nil if v.nil?

      # free memory in GB
      v = (v.to_f / (1024*1024*1024)).round(3)
      #v = v.to_i

      v
    end


  end
end

