module Gexcore::Monitoring

  class NodesMonitoring < Gexcore::BaseService
    CHECKS = {
        'keepalive' => {
            name: 'keepalive',
            title: 'Keepalive',
            sensu_counter_name: 'keepalive',
            #method_check_value: "get_value_keepalive"
            class_name: "Keepalive"


        }
    }

    COUNTERS = {
        :cpu=>{name: 'CPU', sensu_counter_name: 'metrics_cpu', class_name: 'Cpu'},

        :memory=>{name: 'Memory free', sensu_counter_name: 'metrics_memory', needs_total:true, class_name: 'Memory'},
        :memory_total=>{name: 'Memory total', sensu_counter_name: 'metrics_memory', class_name: 'MemoryTotal'},

        :hdd_used=>{name: 'HDD used', sensu_counter_name: 'metrics_hdd', class_name: 'Hdd'},
        :hdd_total=>{name: 'HDD total', sensu_counter_name: 'metrics_hdd', needs_total:true, class_name: 'HddTotal'},

    }



    ###

    def self.get_checks_for_nodes_by_user(user, nodes_or_uids)
      team_id = user.team_id

      return {} unless nodes_or_uids.is_a?(Array)


      if nodes_or_uids[0].is_a?(String) || nodes_or_uids[0].is_a?(Fixnum)
        # it is array of UIDs
        # filter for this user
        clusters_ids = user.team.clusters.w_not_deleted.pluck(:id)
        nodes = Node.where(cluster_id: clusters_ids, uid: nodes_or_uids).all
      else
        # it is array of Nodes
        nodes = nodes_or_uids
      end


      #
      res = {}
      nodes.each do |node|
        res[node.uid] = get_checks_for_node(node)
      end

      res
    end


    def self.get_checks_for_node(node)
      data = {}

      #
      CHECKS.each do |check_name, check_info|
        data[check_name] = get_check_for_node(node, check_name)
      end

      data
    end


    ###
    def self.get_check_for_node(node, check_name)
      return nil if node.nil?

      check_info = CHECKS[check_name]

      # get data from sensu
      check_data = get_sensu_counter_data(node, check_name, check_info)

      # parse data
      return Gexcore::Monitoring::Checks::Result.build_from_sensu_check_data(check_data, check_name, check_info)
    end




    ### metrics

    def self.get_all_metrics_for_node(node, counters=nil)
      data = {}

      COUNTERS.each do |key,value|
        data[key] = get_metrics_for_node node, key, time_from=Time.now-2.hours
      end

      data
    end




    def self.get_metrics_for_node(node, counter_name, time_from=(Time.now.utc.to_i - 60*60))
      counter_info = COUNTERS[counter_name]

      # get from sensu
      data = get_sensu_counter_data(node, counter_name, counter_info)

      # parse data
      res = Gexcore::Monitoring::Metrics::Result.build_from_sensu_msg(data, counter_name, counter_info)

      res
    end



    ### metrics history

    def self.get_node_metrics_history(node,counter_name, tnow, time_period)
      node_uid = node.uid

      #
      time_from = tnow - time_period*60
      time_to = tnow


      # OLD
      #resp = Gexcore::::MonitoringService.get_counter_data_history(node_uid, COUNTERS[counter_name.to_sym][:sensu_counter_name], time_from)
      #resp =  Gexcore::Monitoring::MetricsHistory.get_counter_data_history(node_uid, COUNTERS[counter_name.to_sym][:sensu_counter_name], 60, time*60,tnow)

      counter_info = COUNTERS[counter_name.to_sym]

      return nil if counter_info.nil?

      # res - array of MetricsResult
      a_metrics_result =  Gexcore::Monitoring::MetricsHistory::Service.get_metrics_history_for_node(node_uid, counter_name, counter_info, time_from, time_to)

      if a_metrics_result.nil? || a_metrics_result.length<=0
        return nil
      end

      # to json
      res = a_metrics_result.map do |r|
        [r.date, r.value]
      end

      return res
    end


    ### get check/counter data
    def self.get_sensu_counter_data(node, counter_name, counter_info)
      #
      sensu_node_uid = 'node_'+node.uid
      data = Gexcore::Monitoring::Sensu::ApiService.get_result_value(sensu_node_uid, counter_info[:sensu_counter_name], 600)
      return nil if data.nil? || data['check'].nil? || data['check']['output'].nil?

      data
    end


    ### counters

    ### redis operations

    def self.redis_key_for_check(node, check_name)
      #"#{Apiservice::Settings.redis_counters_prefix}.node.#{node.uid}.checks.#{check_name}"
      "result:#{node.uid}:#{check_name}"
    end



    ### using RabbitMQ
    # NOT USED
    def self.get_counter_data_rabbitmq(node, counter_name, ttl=60)

      begin
        require 'bunny'

        # rabbitmq connection
        conn = rabbit_connection(node)
        conn.start

        # channel
        ch = conn.create_channel

        # exchanges
        exchange_main = rabbit_create_exchange_main ch
        exchange_cache = rabbit_create_exchange_cache ch, exchange_main, node, counter_name


        # queue
        queue = rabbit_create_queue_node_counter(ch, exchange_cache, node, counter_name)

        # get last value from queue
        data = nil
        a = []
        queue.subscribe(:timeout => 5) do |delivery_info, metadata, body|
          s_data = body
          begin
            # parse
            data = JSON.parse(s_data)
            next if data.nil?

            # date
            sd = data['check']['executed']
            d = Time.at(sd.to_i).utc.to_datetime
            next if d.nil?

            # check date
            now = Time.now.utc
            next if now.to_f-d.to_f > ttl

            # status
            status = data['check']['status'].to_i


            gex_logger.debug "counter", "value #{counter_name}", {
                                       counter: counter_name, date: d, status:  status,
                                     key: delivery_info.routing_key, body: data}

            a << d
          rescue => e_parse
            gex_logger.debug "counter", "cannot parse counter data", {body: body}
          end
        end

        gex_logger.debug "counter", "counter values ", {a: a}

        #
        ch.close
        conn.close

       return data
      rescue => e
        gex_logger.exception('Cannot process request', e)
        return nil
        #return Apiservice::Response.res_error_exception('Cannot process request', e)
      end

      return nil
    end




    ### rabbitmq operations

    def self.rabbit_connection(node)
      #
      conn = Bunny.new(
          :hostname => Apiservice::Settings.rabbit_url_private,
          :user => Apiservice::Settings.rabbit_sensu_username,
          :password => Apiservice::Settings.rabbit_sensu_password,
          :vhost => Apiservice::Settings.rabbit_sensu_vhost
      )

      conn
    end

    def self.rabbit_create_exchange_main(ch)
      ch.topic(rabbit_exchange_counters,
               :durable=>true,
               :auto_delete => false
      )
    end

    def self.rabbit_create_exchange_cache(ch, exchange_main, node, counter_name)
      exchange_cache = Bunny::Exchange.new(
          ch, :"x-recent-history", rabbit_exchange_counters_cache(node.uid, counter_name),
          :durable=>false, :auto_delete => false, :arguments=>{:"x-recent-history-length"=>4}
      )

      #exchange_cache.bind(exchange_main, {:routing_key=>'#'})
      exchange_cache.bind(exchange_main, {:routing_key=>rabbit_key_node_counter(node.uid, counter_name)})

      exchange_cache
    end

    def self.rabbit_create_queue_node_counter(ch, exchange_cache, node, counter_name)

      key = rabbit_key_node_counter(node.uid, counter_name)
      #unless conn.queue_exists?(queue_name)

      # create queue
=begin
      queue_name = rabbit_queue_node_counter(node.uid, counter_name)
      queue = ch.queue(queue_name,
                       :auto_delete => false,
                       :exclusive => false,
                       :durable=>false,
                       arguments: {
                           'x-message-ttl' => 30*1000
                       }
      ).bind(exchange_cache, :routing_key => key)
=end

      # create temp queue
      ttl = counter_name=='keepalive' ? 2*60*60*1000 : 4*60*1000
      queue = ch.queue(rabbit_queue_node_counter_temp(node.uid, counter_name),
                       :auto_delete => true,
                       :exclusive => false,
                       :durable=>false,
                       arguments: {
                           'x-message-ttl' => ttl
                       }
                       ).bind(exchange_cache, :routing_key => key)
      #end

    end


    ### rabbitmq settings

    def self.rabbit_exchange_counters
      Apiservice::Settings.rabbit_sensu_prefix+".nodes.checks"
    end


    def self.rabbit_exchange_counters_cache(node_uid, counter_name)
      Apiservice::Settings.rabbit_sensu_prefix+".node.#{node_uid}.checks_cache.#{counter_name}"
    end

=begin
    def self.rabbit_queue_node_counter(node_uid, counter_name)
      config.rabbit_sensu_prefix+".node.#{node_uid}.checks.#{counter_name}"
    end
=end

    def self.queue_name_random
      d = Date.today
      d.strftime('%y%j') + Gexcore::TokenGenerator.random_string_digits(8)
    end

    def self.rabbit_queue_node_counter_temp(node_uid, counter_name)
      r = queue_name_random
      config.rabbit_sensu_prefix+".node.#{node_uid}.checks.#{counter_name}.#{r}"
    end

    def self.rabbit_key_node_counter(node_uid, counter_name)
      "#{node_uid}.checks.#{counter_name}"
    end


  end
end

