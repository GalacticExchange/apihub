class ClusterServicesController < AccountBaseController

=begin
  def show_info
    # input
    service_name = params[:serviceName] || ''
    cluster_uid = params[:clusterId] || params[:clusterID]
    node_uid = params[:nodeId] || params[:nodeID] || ''

    if service_name.blank?
      return return_json(Gexcore::Response.res_error_badinput('','Service is not set'))
    end

    # work
    res = Gexcore::ClusterServices::Service.get_service_info_by_user(current_user, cluster_uid, node_uid, service_name)

    return_json(res)
  end
=end

  def index
    # input
    service_name = params[:name] || params[:serviceName]
    cluster_uid = params[:clusterId] || params[:clusterID]
    app_uid = params[:applicationID] || params[:applicationId]
    cont_uid = params[:containerID] || params[:containerId]
    node_uid = params[:nodeId] || params[:nodeID] || ''

    services_type = params[:servicesType] || params[:services_type]

    #if service_name.blank?
    #  return return_json(Gexcore::Response.res_error_badinput('','Service is not set'))
    #end

    filter_opts = {}
    filter_opts[:service_name] = service_name if service_name
    filter_opts[:cluster_uid] = cluster_uid if cluster_uid
    filter_opts[:node_uid] = node_uid if node_uid
    filter_opts[:app_uid] = app_uid if app_uid
    filter_opts[:cont_uid] = cont_uid if cont_uid
    filter_opts[:services_type] = services_type if services_type

    # work

    res = Gexcore::ClusterServices::Service.get_service_list_by_user(current_user, filter_opts)

    return_json(res)
  end



end
