module Gexcore::Monitoring
  class OldHistoryService < ::Gexcore::BaseService

    ### history from kafka

    # interval (between 2 points), period (from first to last) - in seconds
    def self.get_counter_data_history(node_uid, counter_name, interval, period, tnow)

      res = []

      # get current value from sensu
      sensu_node_uid = "node_"+node_uid
      res_current = Gexcore::Monitoring::Sensu::ApiService.get_result_value sensu_node_uid, counter_name

      # ??
      last_executed = (res_current['check']['executed'].to_i rescue 0)
      return nil if last_executed<=0

      time_from = tnow - period
      topic = "gex.#{node_uid}.checks.#{counter_name}"

      require 'kafka'
      kafka = Kafka.new(
          seed_brokers: ["#{config.counters_kafka_host}:9092"],
          connect_timeout: 30,
          socket_timeout: 20,
      #logger: logger,
      )

      offset_key = gen_offset_key(counter_name,node_uid,interval,period)
      offset = $redis.get(offset_key)

      begin
        resp = nil
        if offset
          resp = get_messages_w_offset(kafka,topic,offset,time_from,last_executed)
        else
          resp = get_all_messages_from(kafka,offset,topic,time_from,last_executed)
        end

        #resp = offset ? get_messages_w_offset(kafka,topic,offset,time_from,last_executed) : get_all_messages_from(kafka,offset,topic,time_from,last_executed)
        res = resp[:res]
        offset = resp[:offset]

        kafka.close

      rescue Timeout::Error => e
        gex_logger.critical("debug_stats", "kafka msg timeout", {})
      rescue Kafka::Error => e
        gex_logger.critical("debug_stats", "kafka error", {e: e})
        return {:res=>nil,:err=>e}
      rescue Exception => e
        gex_logger.critical("debug_stats", "kafka ex", {ex: e})
      end


      if res.any?
        $redis.set offset_key, offset
        days = 7
        ttl = days*24*60*60
        #ttl = 1
        $redis.expire offset_key, ttl
      end

      {:res=>res}
    end

    def self.gen_offset_key(counter_name,node_uid,interval,period)
      config.redis_prefix+":node_metrics:#{counter_name}_#{node_uid}_#{interval}_#{period}"
    end


    def self.get_messages_w_offset(kafka,topic,offset,time_from,last_executed)
      res = []
      tmp_offset = offset.to_i
      new_offset = offset

      puts "get from offset #{offset}"

      # fx fetch_messages
      timeout 30 do
        while true do

          #
          puts "get from kafka: from offset #{tmp_offset}"

          resp = kafka.fetch_messages(topic: topic, partition: 0, offset: tmp_offset)

          if resp.empty?
            puts "no data in kafka"
            break
          end


          #if tmp_offset == resp.last.offset
          #  puts "last message == tmp offset"
          #  break
          #end

          last_message = resp.last

          #
          tmp_offset = last_message.offset.to_i

          # check last message


          # debug
          ti = last_message.key.to_i
          tt = Time.at(ti)
          puts "last message: #{last_message.offset}, #{ti}, #{tt}"

          first_message = resp.first
          ti = first_message.key.to_i
          tt = Time.at(ti)
          puts "first message: #{first_message.offset}, #{ti}, #{tt}"

          #

          t = (last_message.key.to_i rescue 0)
          if t>0
            next if t < time_from
            #break if t>=last_executed
          end


          if resp.count==1 && tmp_offset == resp.last.offset
            puts "one msg == tmp offset"
            break
          end



          # process messages
          puts "*********** process messages"

          resp.each do |message|
            t = (message.key.to_i rescue 0)
            if t>0
              next if t < time_from
              break if t>=last_executed

              if res.empty?
                new_offset = message.offset
              end


              # add message to result
              res << message.value
            end
          end

        end
      end

      {:res=>res,:offset=>new_offset}
    end


    def self.get_all_messages_from(kafka,offset,topic,time_from,last_executed)

      max_messages = 1000000
      ind = 0
      res = []

      timeout 60 do
        kafka.each_message(topic: topic, start_from_beginning: true, max_wait_time: 1) do |message|

          ind +=1
          break if ind>max_messages

          t = (message.key.to_i rescue 0)

          if t>0
            next if t < time_from
            break if t>=last_executed
            offset = message.offset if res.empty?
            res << message.value
          end
        end
      end

      {:res=>res,:offset=>offset}
    end









    # fill_freq = in secs
    def self.get_counter_data_history_old(node_uid, counter_name, time_from, fill_holes=true, fill_freq=10)
      #gex_logger.critical("debug_stats", "stats: get_counter_data_history ", {node_uid: node_uid, counter_name: counter_name})

      # get current value from sensu
      sensu_node_uid = "node_"+node_uid
      res_current = Gexcore::Monitoring::Sensu::ApiService.get_result_value sensu_node_uid, counter_name

      last_executed = (res_current['check']['executed'].to_i rescue 0)

      #gex_logger.critical("debug_stats", "stats: last_executed ", {last_executed: last_executed})


      if last_executed<=0
        return nil
      end

      # get from kafka
      topic = "gex.#{node_uid}.checks.#{counter_name}"

      require 'kafka'
      kafka = Kafka.new(
          seed_brokers: ["#{config.counters_kafka_host}:9092"],
          connect_timeout: 30,
          socket_timeout: 20,
      #logger: logger,
      )

      # get all messages
      max_messages = 1000000
      ind = 0
      res = []
      begin
        timeout 20 do
          kafka.each_message(topic: topic, start_from_beginning: true, max_wait_time: 1) do |message|
            #gex_logger.critical("debug_stats", "stats: kafka msg ", {ind: ind})

            ind +=1

            break if ind>max_messages

            #puts "--- offset: #{message.offset}, partition: #{message.partition}, key: #{message.key}"
            #puts "data: #{message.value}"

            # check if enough
            t = (message.key.to_i rescue 0)

            if t>0

              next if t < time_from

              break if t>=last_executed

              # add
              res << message.value
            end

            # TODO: fill gap
            # from last point to current point

          end
        end
      rescue Timeout::Error
        gex_logger.critical("debug_stats", "kafka msg timeout", {})

        #puts 'kafka -- timed out '
        x=0
      rescue Kafka::Error => e
        gex_logger.critical("debug_stats", "kafka error", {e: e})
        return {:res=>nil,:err=>e}
      rescue Exception => e
        gex_logger.critical("debug_stats", "kafka ex", {ex: e})
      end

      # TODO: fill before
      if fill_holes
        # fill nil from time_from to first point

      end

      #
      return {:res=>res}
    end





  end
end

