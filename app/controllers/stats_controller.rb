class StatsController < AccountBaseController

  def nodes

    check_current_cluster || return

    res_json = {}

    @nodes = @current_cluster.nodes.w_not_deleted.to_a
    @checks = Gexcore::Monitoring::NodesMonitoring.get_checks_for_nodes_by_user(current_user, @nodes)


    @nodes.each do |node|
      # checks
      node_checks = @checks[node.uid]
      node_checks_ok = Gexcore::Monitoring::Checks::Result.is_all_ok(node_checks)


      #
      #res = Gexcore::Nodes::Service.node_state_with_performance node
      #node_state = res[:state][:value]

      if node.status != 'active' || !node_checks_ok
      #if node_state!="running" || node.status != 'active'
        res = {
            "#{node.uid}" =>{
                'nodeName'=> node.name,
                'working'=>false
            }
        }
        res_json.merge!(res)
      else
        # metrics
        #node_metrics = res[:counters]
        node_metrics = Gexcore::Monitoring::NodesMonitoring.get_all_metrics_for_node(node)


        # node uid => node_uid
        # hash with node cpu+ram+disk info => res
        # hash with res hashes => res_json

        res = {
            "#{node.uid}" =>{
                'nodeName'=> node.name,
                'working'=>true,
                'cpu' =>{
                    'apps'=>{
                        'Used CPU'=>{'used'=> "#{node_metrics[:cpu].value}"},
                        #'mysql'=>{'used'=> "#{(0..30).to_a.sample}"}
                    },
                    'colors'=>{

                        'Used CPU'=>'#1d87e4',
                        #'mysql'=>'#1CAF9A'
                    }
                },
                'ram'=>{
                    'all'=>"#{node_metrics[:memory_total].value}",
                    'used'=>"#{node_metrics[:memory].value}"
                },
                'disk'=>{
                    'all'=>"#{node_metrics[:hdd_total].value}",
                    'used'=>"#{node_metrics[:hdd_used].value}"
                }
            }
        }
        res_json.merge!(res)
      end
    end

    render json: res_json
  end


  def node_history
    # TODO: new result format

    @node_uid = params[:uid]
    @counter_name = params[:type]
    @node = Node.get_by_uid(@node_uid)
    tnow = Time.now.utc.to_i

    # TODO: check user permissions

    #
    data = Gexcore::Monitoring::NodesMonitoring.get_node_metrics_history(@node, @counter_name, tnow, 122)

    #puts "data: #{data}"

    if data
      @res_points = Gexcore::Monitoring::StatisticsService.normalize_points(data,tnow,7200,60)
      @res_points.each { |pair| pair[0]=Time.at(pair[0]) }
      @resp = [true,@res_points]

      # TODO! tmp fx here
      if @counter_name=="memory"
        # todo -> make method - get_total_memory
        node_metrics = Gexcore::Monitoring::NodesMonitoring.get_all_metrics_for_node(@node)
        memory_total = node_metrics[:memory_total].value if node_metrics[:memory_total]
        @resp.push(memory_total)
      end

    else
      @resp = [false,nil]
    end

    render json: @resp
  end


  def node

    node_uid = params[:uid]
    counter_name = params[:type]
    last_time = params[:last_time]
    last_time_int = Integer(last_time)
    interval = (params[:interval].to_i rescue nil)
    interval ||= 60

    tnow = Time.now.utc.to_i
    @node = (Node.get_by_uid(node_uid) rescue nil)

    if tnow < last_time_int + (interval * 1.5)
      @resp = [false,nil]
    else
      data = Gexcore::Monitoring::NodesMonitoring.get_node_metrics_history(@node, counter_name, tnow, 10)

      # real-time part
      @node_metrics = Gexcore::Monitoring::NodesMonitoring.get_all_metrics_for_node(@node)

      # if we need total value (memory,hdd)
      if Gexcore::Monitoring::NodesMonitoring::COUNTERS[counter_name.to_sym][:needs_total]
        all_metric = (@node_metrics[(counter_name+"_total").to_sym].value rescue nil)
      end


      if data
        @resp = Gexcore::Monitoring::StatisticsService.find_last_point(data,last_time,interval,all_metric)
      else
        @resp = [true,[all_metric, nil, Time.at(last_time_int + interval)]]
      end
    end

    render json: @resp
  end

end
