module Gexcore::Monitoring::Metrics

  class Result
    attr_accessor :name, :description, :date, :value

    def initialize(_name)
      @name = _name
    end


    #
    def to_s
      "#{name}. #{Time.at(date.to_i)}, #{value}"
    end

    ### build

    def build_from_data(data, counter_info)
      output = Gexcore::Monitoring::Metrics::Result.parse_output(data)

      return false if output.nil?


      @value = get_value_from_output(output)

      return false if @value.nil?

      # date
      #d = Gexcore::Monitoring::Service.get_date_from_counter_data(data)
      @date = Gexcore::Monitoring::Sensu::CounterDataParser.get_ts_from_counter_data(data)

      # OK
      true
    end



    # msg - event message in sensu
    def self.build_from_sensu_msg(msg, counter_name, counter_info)
      cls_result = Object.const_get("Gexcore::Monitoring::Metrics::#{counter_info[:class_name]}")

      res = cls_result.new(counter_name)

      # todo: set result to false and return
      return res if msg.nil?

      res.build_from_data(msg['check'], counter_info)

      res
    end

    # msg - event message in kafka
    def self.build_from_kafka_msg(msg, counter_name, counter_info)
      cls_result = Object.const_get("Gexcore::Monitoring::Metrics::#{counter_info[:class_name]}")

      sensu_msg_data = (JSON.parse(msg.value) rescue nil)

      res = cls_result.new(counter_name)
      res.build_from_data(sensu_msg_data, counter_info)

      res
    end


    ### helpers

    def self.parse_output(data)
      output = nil
      # parse output
      begin
        output = JSON.parse(data['output']) rescue data['output']
      rescue => e
        #gex_logger.exception('cannot parse counter data', e, {output: data['check']['output']})
        return nil
      end

      output
    end

  end
end

