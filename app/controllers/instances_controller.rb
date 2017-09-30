class InstancesController < BaseController


  def create
    # input
    version = params[:version] || params['version'] || ''
    sysinfo = params[:sysinfo] || params['systemInfo'] || '{}'

    instance_id = params[:instanceID] || params['instanceID'] || ''

    # work
    res = Gexcore::InstancesService.add_instances(instance_id, version, sysinfo)

    # log
    gex_logger.log_response(res, 'add_instances', "Instance added", 'add_instances_error', {instance_uid: instance_id})

    # response
    return_json(res)
  end
end

