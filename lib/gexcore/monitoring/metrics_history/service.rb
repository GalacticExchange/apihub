module Gexcore::Monitoring::MetricsHistory

  class Service < ::Gexcore::BaseService

    ### main method

    # time_from, time_to
    def self.get_metrics_history_for_node(node_uid, counter_name, counter_info, time_from, time_to)
      res = []

      # get current value from sensu
      sensu_node_uid = "node_"+node_uid
      sensu_counter_name = counter_info[:sensu_counter_name]
      res_current = Gexcore::Monitoring::Sensu::ApiService.get_result_value sensu_node_uid, sensu_counter_name

      last_executed = (res_current['check']['executed'].to_i rescue 0)
      return nil if last_executed<=0

      #
      topic = get_kafka_topic(node_uid, counter_name, counter_info)

      # time
      #time_to = last_executed

      res_kafka_messages = nil

      #
      begin
        res_kafka_messages = get_messages_window(topic,time_from,time_to)
      rescue Timeout::Error => e
        gex_logger.warning("debug_stats", "kafka msg timeout", {})
      rescue Kafka::Error => e
        gex_logger.warning("debug_stats", "kafka error", {e: e})
        #return {:res=>nil,:err=>e}
      rescue => e
        #gex_logger.critical("debug_stats", "general ex", {ex: e})
      end

      # if no data
      if res_kafka_messages.nil?
        return nil
      end

      # parse result
      res = parse_kafka_messages_to_result(res_kafka_messages, counter_name, counter_info)

      res
    end


    def self.parse_kafka_messages_to_result(messages, counter_name, counter_info)

      return nil if messages.nil?

      res_messages = messages.map do |msg|
        Gexcore::Monitoring::Metrics::Result.build_from_kafka_msg(msg, counter_name, counter_info)
      end

      res_messages
    end


    #
    def self.get_messages_window(topic, time_from,time_to)
      kafka = Kafka.new(
          seed_brokers: ["#{config.counters_kafka_host}:9092"],
          connect_timeout: 30,
          socket_timeout: 20,
      #logger: logger,
      )

      # find first message
      first_msg = nil
      first_msg_time = nil

      begin
        Timeout.timeout 3 do
          kafka.each_message(topic: topic, start_from_beginning: true, max_wait_time: 2) do |message|
            first_msg = message
            break
          end
        end
      rescue => e
        #puts "cannot connect to Kafka to get first message from topic #{topic}"
      end


      if first_msg
        first_offset = first_msg.offset
        first_msg_time = first_msg.key.to_i
      end


      # offset for this time - from cache
      offset = get_offset_for_time(topic, time_from)

      # get first
      if offset.nil?
        if !first_offset.nil?
          offset = first_offset

          # save offset
          save_offset_for_time(topic, first_msg_time, first_offset)
        end

      end


      # nothing
      if offset.nil?
        return []
      end


      # start from offset
      res = []

      current_offset = offset
      last_message_time = 0
      last_message_offset = -1

      # get from kafka
      Timeout.timeout 20 do
        while true do
          #puts "get from kafka offset: #{current_offset}"

          resp = kafka.fetch_messages(topic: topic, partition: 0, offset: current_offset, max_wait_time: 2)

          if resp.empty?
            #puts "no data in kafka"
            break
          end

          # process messages
          process_messages(res, resp, time_from, time_to)

          # next step
          last_message = resp.last

          last_message_offset = last_message.offset
          last_message_time = last_message.key.to_i

          #
          current_offset = last_message_offset+1

        end
      end

      # save offset to cache
      last_message = res.last
      if last_message
        last_message_offset = last_message.offset
        last_message_time = last_message.key.to_i

        save_offset_for_time(topic, last_message_time, last_message_offset)
      end


      # list of KafkaMessage
      return res
    end


    def self.process_messages(res, messages, time_from, time_to)
      # process messages
      #puts "*********** process messages"

      messages.each do |message|
        t = (message.key.to_i rescue 0)
        if t>0
          next if t < time_from
          break if t>=time_to

          if res.empty?
            new_offset = message.offset
          end


          # add message to result
          res << message
        end

      end


    end


    ### offsets management

    def self.redis_key_offsets(topic)
      key = "#{Rails.configuration.gex_config[:redis_prefix]}:node_metrics:#{topic}:offsets_by_time"
      key
    end

    def self.get_offset_for_time(topic, time)
      key = redis_key_offsets(topic)

      #
      #delta = 300
      #tnow = Time.now.utc.to_i
      a = $redis.zrevrangebyscore key, time, 0

      #puts "found for time #{Time.at(time)}: #{a}"

      v = nil
      if a && a.count>0
        v = a.first.to_i
      end

      v
    end

    def self.save_offset_for_time(topic, time, offset, min_time_freq=60)
      key = redis_key_offsets(topic)

      # do not save if too freq points
      a_last = $redis.zrange key, -1, -1
      #puts "last: #{a_last}"

      if a_last
        m_last = a_last[0]
        t_last = $redis.zscore key, m_last
        t_last = t_last.to_i

        if time-t_last < min_time_freq
          #puts "do not save offset for time #{Time.at(time)} - too freq (#{min_time_freq}"
          return false
        end
      end




      # save
      $redis.zadd key, time.to_s, offset
      $redis.expire key,  1*24*60*60

      #puts "save for time #{Time.at(time)}, t=#{time}, offset = #{offset}"

      # remove old data
      t_old = (Time.now.utc - 24.hours).to_i

      n = $redis.zremrangebyscore key, 0, t_old

      #puts "remove till #{Time.at(t_old)}. removed #{n} from cache"

    end

    def self.clean_offsets(topic)
      key = redis_key_offsets(topic)
      $redis.del key
    end



    ### helpers - kafka

    def self.get_kafka_topic(node_uid, counter_name, counter_info)
      "gex.#{node_uid}.checks.#{counter_info[:sensu_counter_name]}"
    end
  end

end
