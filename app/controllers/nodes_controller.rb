class NodesController < AccountBaseController

  layout "sidebar_view"
  before_action { @page_selected = 'nodes' }


  def model
    #@current_cluster.nodes.w_not_deleted
    @current_cluster.nodes
  end


  #
  #autocomplete :node, :name, {:where => ("status <> #{Node.statuses[:removed]} and cluster_id = #{which_cluster}")}

  # autocomplete
  def autocomplete_node_name

    # before use 'model'
    check_current_cluster || return

    q = params[:q]

    is_full_search = nil
    like_clause = 'LIKE'

    #
    items = model.where(["LOWER(#{'nodes'}.#{'name'}) #{like_clause} ?", "#{(is_full_search ? '%' : '')}#{q.downcase}%"]).limit(10).order("id asc")

    #items = items.limit(10).order("id asc")

    #
    render :json => Gexcore::Common.items_to_json(items, 'uid', 'name')
  end


  # create node
  def create
    # input
    cluster_uid = params[:clusterID] || ''
    instance_uid = params[:instanceID] || ''

    #
    dirname = params['directoryName'] || ''
    sysinfo = params[:systemInfo] || {}
    extra_fields = {}
    extra_fields[:host_type_name] = params[:hostType] || params[:host_type] || NodeHostType::DEFAULT_NAME
    extra_fields[:node_type_name] = params[:nodeType] || params[:node_type_name] || ClusterType::DEFAULT_NAME
    extra_fields[:custom_name] = params[:customName] || params[:custom_name]

    # hadoop
    extra_fields[:hadoop_app] = to_boolean(param_first_not_nil(:hadoop_app, :hadoopApp))

    # options
    node_options = get_param_value_hash(:options, {})
    extra_fields[:options] = node_options


    #
    user = current_user
    cluster = Cluster.get_by_uid(cluster_uid)


    # create node
    res = Gexcore::Nodes::Service.create_node_by_user(instance_uid, user, cluster, sysinfo, extra_fields)


    # log
    gex_logger.log_response(res, 'node_installed', "Node was installed: :node_name", 'node_install_error')

    # return res
    if res.success?
      node = Node.get_by_id(res.data[:node_id])
      return_json_data(node.to_hash_created)
    else
      return_json(res)
    end
  end


  ### add node

  def add
    # input
    cluster_uid = params[:clusterID]
    n_nodes = (params[:nNodes] || 1).to_i


    # opts
    opts = {}

    opts[:disk_storage] = (params[:diskStorage] || 100).to_i
    opts[:instance_type] = params[:instanceType]

    # hadoop
    opts[:hadoop_app] = param_first_not_nil(:hadoop_app, :hadoopApp)

    #
    @res = Gexcore::Nodes::Service.add_nodes_to_cluster_by_user(current_user, cluster_uid, n_nodes, opts)

    return_json(@res)
  end

  def no_clusters
    if @current_cluster.nil?
      res = Gexcore::Response.new
      return res.set_error_forbidden('', 'You have no clusters.', '')
    end
  end

  def check_name
    check_current_cluster || return

    res = Gexcore::Response.new

    node_name = params[:name]
    valid_hostname_regex = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/

    if (node_name =~ valid_hostname_regex).nil?
      res.set_error_badinput('wrong_node_name', 'Node name invalid', 'node name not valid as hostname')
    elsif node_name.length > 40
      res.set_error_badinput('wrong_node_name', 'Node name is too long. Max length - 40 symbols.', 'node name is too long. max length - 40.')
    else
      if Node.w_not_deleted.where(name: node_name).empty?
        res.set_data
      else
        res.set_error_badinput('wrong_node_name', 'Name is already taken. Please use unique node name.', 'node name is already taken')
      end
    end

    respond_to do |format|
      format.html { raise 'not supported'  }
      format.json{ return_json(res) }
    end
  end


  def get_name
    name = Gexcore::Nodes::Service.get_name
    return_json Gexcore::Response.res_data({name: name})
  end


  def index

    # input
    init_cluster

    mode = params[:mode] || 'info'

    # work
    nodes_resp = Gexcore::Nodes::Service.get_nodes_for_cluster_by_user(current_user, @current_cluster)

    if nodes_resp
      @nodes = nodes_resp.to_a
      # pack result
      @res = Gexcore::Nodes::Service.list_nodes_to_json(@nodes, mode)
    else
      @res = Gexcore::Response.res_error_badinput('', 'no nodes found for this cluster', "no nodes found for this cluster")
    end

    respond_to do |format|
      format.html {}
      format.json { return_json(@res) }
    end
  end


  def update
    # input
    @node_uid = get_node_uid
    @node_name = params[:name] || ''
    @cmd = params[:command] || ''

    #
    user = current_user


    # send command to node
    if !@node_uid.nil? && !@node_uid.blank?
      node = Node.get_by_uid(@node_uid)
    else
      node = Gexcore::Nodes::Service.get_node_by_name(@current_cluster, @node_name)
    end


    #
    res = Gexcore::Nodes::Control.do_action_with_node_by_user(user, node, @cmd)
    #res = Gexcore::NodesControlService.do_action_with_node(node, @action)

    gex_logger.log_response(res, 'node_control_command_sent', "Command was sent to node :node_name", 'node_control_command_send_error')

    return_json(res)
  end

  # uninstall node
  def uninstall
    # input
    node_uid = get_node_uid

    # work
    res = Gexcore::Nodes::Service.uninstall_node_by_user(current_user, node_uid)

    # log
    #gex_logger.log_response(res, 'node_uninstalled', "Node was uninstalled", 'node_uninstall_error')

    #
    return_json(res)
  end

  # delete node
  def destroy
    # input
    node_uid = get_node_uid

    # work
    res = Gexcore::Nodes::Service.remove_node_by_user(current_user, node_uid)

    # log
    #gex_logger.log_response(res, 'node_removed', "Node was removed", 'node_remove_error')

    #
    return_json(res)
  end


  def edit

    # input
    node_uid = get_node_uid


    node = Node.get_by_uid(node_uid)
    if !node.nil?
      remove_check(node)
    end

    # work
    if current_user
      @res = Gexcore::Nodes::Service.get_node_info_by_user(current_user, node_uid)
    elsif @res_auth.data[:agent_node_id].present?
      @res = Gexcore::Nodes::Service.get_node_info_by_agent(@res_auth.data[:agent_node_id], node_uid)
    end

    @node = @item = @res.data[:node]
    # get data for page
    #@containers = @node.containers

    respond_to do |format|
      format.html {
        if @res.error? || @item.nil?
          redirect_to NgRoutes::NODES.sub('{cluster_id}', @current_cluster.uid)
        end
      }
      format.json {
        if @res.error?
          return return_json(@res)
        else
          return return_json_data({node: @item.to_hash})
        end
      }
    end


  end

  def show

    # input
    node_uid = get_node_uid

    opts = {}
    opts[:with_removed] = to_boolean(params[:with_removed])

    # work
    if current_user
      @res = Gexcore::Nodes::Service.get_node_info_by_user(current_user, node_uid, opts)
    elsif @res_auth.data[:agent_node_id].present?
      @res = Gexcore::Nodes::Service.get_node_info_by_agent(@res_auth.data[:agent_node_id], node_uid)
    end


    item = @res.data[:node]

    if @res.success? && !item.nil?
      @res.data[:node] = @res.data[:node].to_hash
    end

    # get data


    respond_to do |format|
      format.html {
        if @res.error?
          redirect_to NgRoutes::NODES.sub('{cluster_id}', @current_cluster.uid)
        end
      }
      format.json {
        return_json(@res)
      }
    end

  end


  # todo: deprecated, could be common info+checks
  def show_full
    raise 'deprecated'

    node_uid = get_node_uid

    #@node = Node.get_by_uid(node_uid)

    if current_user
      @res = Gexcore::Nodes::Service.get_node_state_by_user(current_user, node_uid)
    elsif @res_auth.data[:agent_node_id].present?
      @res = Gexcore::Nodes::Service.get_node_state_by_agent(@res_auth.data[:agent_node_id], node_uid)
    end

    respond_to do |format|
      format.html { raise 'not supported' }
      format.json { return_json(@res) }
    end

  end


  def show_state
    raise 'deprecated'

    #
    node_uid = get_node_uid

    # work
    if current_user
      @res = Gexcore::Nodes::Service.get_node_state_by_user(current_user, node_uid)
    elsif @res_auth.data[:agent_node_id].present?
      @res = Gexcore::Nodes::Service.get_node_state_by_agent(@res_auth.data[:agent_node_id], node_uid)
    end

    @item = @res.data[:node]


    respond_to do |format|
      format.html {
        raise 'not supported'
      }
      format.json {
        return_json(@res)
      }
    end

  end


  def send_command
    @node_uid = get_node_uid
    @node = (Node.get_by_uid(@node_uid) rescue nil)

    @cmd = params[:cmd]

    @res = Gexcore::Nodes::Control.do_action_with_node_by_user(current_user, @node, @cmd)

    respond_to do |format|
      format.html {}
      format.json { render :json => @res }
    end
  end

  def show_info_containers_all
    # input
    node_uid = get_node_uid

    # work
    node = Node.get_by_uid(node_uid)


    # check permissions
    if !(user.can? :view_node_info, node)
      return Response.res_error_forbidden("view_node_error", 'No permissions to view this node')
    end


    #
    res = Gexcore::Nodes::Service.get_node_info_all(node)

    return_json(res)
  end

  def show_properties_install
    # input
    node_uid = get_node_uid

    # work
    if current_user
      @res = Gexcore::Nodes::Service.get_node_properties_install_by_user(current_user, node_uid)
    elsif @res_auth.data[:agent_node_id].present?
      @res = Gexcore::Nodes::Service.get_node_properties_install_by_agent(@res_auth.data[:agent_node_id], node_uid)
    end


    return_json(@res)
  end


  #### statistic methods ####

  def statistics

    @page_selected = "stats"

    # input
    node_uid = params[:uid]

    # work
    if current_user
      @res = Gexcore::Nodes::Service.get_node_info_by_user(current_user, node_uid)
      @res1 = Gexcore::Nodes::Service.get_node_state_by_user(current_user, node_uid)
    elsif @res_auth.data[:agent_node_id].present?
      @res = Gexcore::Nodes::Service.get_node_info_by_agent(@res_auth.data[:agent_node_id], node_uid)
    end

    # get data
    if @res.success?
      @item = @res.data[:node]
    end

    @containers = @item.containers unless @item.nil?

    respond_to do |format|
      format.html {
        if @res.error? || @item.nil?
          redirect_to NgRoutes::NODES.sub('{cluster_id}', @current_cluster.uid)
        end
      }
      format.json {
        if @res.error?
          return return_json(@res)
        else
          return return_json_data({node: @item.to_hash})
        end
      }
    end

  end


  private

  def get_node_uid
    get_param_value(:nodeID) || get_param_value(:id) || ''
  end

  def init_node_uid
    @node_uid = get_node_uid
  end


end
