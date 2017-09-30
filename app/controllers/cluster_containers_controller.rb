class ClusterContainersController < AccountBaseController

  layout "sidebar_view"
  before_action {@page_selected = "containers"}

  def model(cluster)
    cluster.containers.w_not_deleted.order('id desc')
  end


  def index
    node_uid = params[:nodeId] || params[:nodeID]
    application_uid = params[:applicationId] || params[:applicationID]

    # input
    cluster_uid = params[:clusterId] || params[:clusterID] || params[:cluster_uid]

    filter_opts = {}
    filter_opts[:cluster_uid] = cluster_uid if cluster_uid

    if node_uid && !node_uid.blank?
      #  return return_json(Gexcore::Response.res_error_badinput('','Node is not set'))
      filter_opts[:node_uid] = node_uid if node_uid
    end

    if application_uid && !application_uid.blank?
      filter_opts[:application_uid] = application_uid
    end

    # work
    @res = Gexcore::Containers::Service.get_containers_list_by_user(current_user, filter_opts)

    node = Node.get_by_uid(node_uid)

    # WTF?? it is broken
    containers_checks = []
=begin
    containers_checks = Gexcore::Monitoring::Checks.conainers_in_node_checks(node)

    containers_checks.each do |check_name, check|
      @res.data.each do |container|
        container[:checks][check_name] = check[container[:basename]]
      end
    end
=end
    #todo containers_checks = Gexcore::Containers::Monitoring.check_container(node)

    if @res.success?
      @containers = @res.data[:containers]
    end

    #
    respond_to do |format|
      format.html {      }
      format.json{        return_json(@res)   }
    end
  end


  def show

    res = Gexcore::Response.new
    check_current_cluster || return

    container_uid = params[:uid] || params[:id] || params[:containerId] || params[:containerID]

    if container_uid.nil? || container_uid.empty?
      return return_json(res.set_error_badinput('', 'no container id provided', 'no container id provided') )
    end

    @container = model(@current_cluster).get_by_uid(params[:uid])
=begin
    node = @container.node
    container_checks = Gexcore::Monitoring::Checks.get_container_checks(@container.basename, node)

    container_hash = @container.to_hash
    container_hash[:checks] = container_checks
=end

    if @container.nil?
      return return_json(res.set_error_badinput('', 'no container found', 'no container found') )
    end



    container_hash = @container.to_hash
    #container_hash[:status_checks] = container_checks

    @res = Gexcore::Response.res_data({
      container: @container.to_hash
    })

    #
    respond_to do |format|
      format.html {      }
      format.json{
        return_json(@res)
      }
    end
  end


  def edit
    @container = model.get_by_uid(params[:uid])
  end


  def update
    check_current_cluster || return

    # input
    @container_uid = get_container_uid
    @container_name = get_container_name
    @cmd = params[:command] || ''

    #
    user = current_user


    # command
    if !@container_uid.nil? && !@container_uid.blank?
      container = Gexcore::Containers::Service.get_by_uid(@container_uid)
    else
      container = Gexcore::Containers::Service.get_by_name(@current_cluster, @container_name)
    end


    #
    res = Gexcore::Containers::Control.do_action_by_user(user, container, @cmd)

    #gex_logger.log_response(res, 'container_control_command_sent', "Command was sent to node :node_name", 'node_control_command_send_error')

    return_json(res)
  end

  private

  def get_container_uid
    get_param_value(:containerID) || get_param_value(:id) || ''
  end

  def get_container_name
    get_param_value(:containerName) || get_param_value(:name) || ''
  end

end
