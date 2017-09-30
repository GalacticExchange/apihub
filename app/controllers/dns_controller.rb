class DnsController < BaseController

  def resolve
    # input
    domain = params[:domain]
    ip = params[:ip]
    t = params[:t] || ''

    if t.blank?
      res = Gexcore::DnsService.get_ip_by_domain(domain)
    elsif t=='ip'
      res = Gexcore::DnsService.get_domain_by_ip(ip)
    end

    return_json(res)
  end

  def update_ip
    # input
    ip = params[:ip]
    domain = params[:domain]
    cluster_id = params[:clusterID] || params[:clusterId]
    node_id = params[:nodeID] || params[:nodeId]

    res = Gexcore::Containers::Service.update_ip_for_container_node(domain, ip, {cluster_id: cluster_id, node_id: node_id})

    return_json(res)
  end

end
