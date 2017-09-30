module Gexcore::Monitoring::Metrics

  class Hdd < ::Gexcore::Monitoring::Metrics::Result


    ###
    def get_value_from_output(output)
      return nil if output.nil?

      v = Gexcore::Monitoring::Sensu::CounterDataParser.parse_hdd_line(output, 'disk_usage.root.used')
      return nil if v.nil?

      # in GB
      v = Gexcore::Monitoring::Checks::Evaluator.mb_to_gb(v)

      v
    end
    

  end
end

