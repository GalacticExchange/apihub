module KafkaHelpers
  #
  require 'csv'
  require 'json'
  require 'timeout'


  # read from kafka until found our event
  def wait_log_event(msg_type, time_in_seconds=60, filter={})
    kafka = $logger.get_kafka
    kafka_topic = Myconfig.config[:kafka_topic]


    #
    #consumer = $logger.kafka_consumer
    #consumer.subscribe(kafka_topic, start_from_beginning: true)

    #
    res = nil

    begin
      # v1
=begin
      timeout time_in_seconds.to_i do
        consumer.each_message do |message|
          data = (JSON.parse(message.value) rescue nil)
          next if data.nil?

          if data["type"] == msg_type
            res = data
            break
          end
        end
      end
=end

      puts "---------- Kafka: read from offset #{$logger.offset}"

      # v2
      filter_msg_types = msg_type.is_a?(String) ? [msg_type] : msg_type

      found = false
      timeout time_in_seconds.to_i do
        while (true) do
          found = false
          kafka.fetch_messages(topic: kafka_topic, partition: 0, offset: $logger.offset).each do |message|
            #
            $logger.offset = message.offset

            row = (JSON.parse(message.value) rescue nil)
            next if row.nil?

            if ['api_request_start', 'gexd_status'].include? row['type_name']
              next
            end

            #
            #puts "--- offset: #{message.offset}, partition: #{message.partition}, key: #{message.key}"
            #puts "data: #{message.value}"
            puts "--- offset: #{message.offset}, partition: #{message.partition}, key: #{message.key}, type: #{row['type_name']}, date: #{row['created_at']}"



            # check msg
            next unless filter_msg_types.include?(row["type_name"])

            # try parse data
            row['data'] = JSON.parse(row['data'])



            filter_ok = true
            filter.each do |k, v|
              f = k.to_s

              # no such field
              if row[f].nil? && row['data'][f].nil?
                filter_ok = false
                break
              end

              # search in columns
              if row[f]!=v && row['data'][f]!=v
                filter_ok = false
                break
              end

              #
            end

            next unless filter_ok

            # ok -found
            res = row
            found = true
            break

          end
          # / fetch_message

          break if found

          sleep 5
        end
      end



    rescue Timeout::Error
      return nil
    end

    #
    res
  end


  # for random string
  def random_string(n)
    (0...n).map { ('a'..'z').to_a[rand(26)] }.join
  end
end
