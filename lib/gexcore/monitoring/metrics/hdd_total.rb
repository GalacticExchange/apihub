module Gexcore::Monitoring::Metrics

  class HddTotal < ::Gexcore::Monitoring::Metrics::Result


    ###
    def get_value_from_output(output)
      v_used = Gexcore::Monitoring::Sensu::CounterDataParser.parse_hdd_line(output, 'disk_usage.root.used')
      v_free = Gexcore::Monitoring::Sensu::CounterDataParser.parse_hdd_line(output, 'disk_usage.root.avail')
      return nil if v_used.nil? || v_free.nil?

      #
      v = v_used + v_free

      # in GB
      v = Gexcore::Monitoring::Checks::Evaluator.mb_to_gb(v)

      v
    end

  end
end

