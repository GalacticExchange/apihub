module Gexcore::Monitoring::Sensu
  class EventsService < ::Gexcore::BaseService

    TTL_SECONDS = 14*24*60*60


    def self.send_message(msg_key, msg_data)
      begin
        conn = Bunny.new(:host => config.rabbit_url_private,
                         :port=>5672, :vhost=>config.rabbit_sensu_vhost,
                         :user => config.rabbit_sensu_username, :password => config.rabbit_sensu_password,
                         :continuation_timeout => 30000,
                         :heartbeat => 30,
                         :automatically_recover => true,
                         :network_recovery_interval => 3,
                         :recover_from_connection_close => true,
        )
        conn.start

        ch = conn.create_channel

        # exchange
        exchange = ch.topic(rabbit_exchange_events)

        # queue
        queue_name = rabbit_queue_events
        q1 = ch.queue(queue_name, :auto_delete => false, :exclusive => false, :durable=>false).bind(exchange, :routing_key => '#')

        # push
        exchange.publish(msg_data.to_json, :routing_key => msg_key, :expiration => TTL_SECONDS*1000)

        gex_logger.debug "", "rabbit event msg published"

        #
        ch.close
        conn.close

      rescue => e
        res = Response.res_error_exception('cannot publish to rabbitmq', e)
        gex_logger.debug_response res, "cannot publish to rabbitmq"
        return res
      end

      Response.res_data
    end

    ###

    def self.send_message_from_hash(row_hash)
      data = row_hash['data'] || row_hash[:data]
      type_name = ''

      #
      if data.is_a? String
        data = JSON.parse(data) rescue {}

        type_name = data['type_name']
      end

      send_message type_name, row_hash
    end


    def self.send_message_from_response(resp)
      send_message resp.error_name, resp.to_sensu_event_message
    end


    ### settings

    def self.rabbit_exchange_events
      config.rabbit_prefix+".api_events"
    end
    def self.rabbit_queue_events
      config.rabbit_prefix+".api_events"
    end

  end
end

