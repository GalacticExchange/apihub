module Gexcore::Containers

  class Service < Gexcore::BaseService

    ### get

    def self.get_by_uid(uid)
      ClusterContainer.where(uid: uid).first
    end

    def self.get_by_basename(cluster, name)
      ClusterContainer.where(cluster_id: cluster.id, basename: name).first
    end

    def self.get_by_name(cluster, name)
      ClusterContainer.where(cluster_id: cluster.id, name: name).first
    end

    def self.get_slave_by_basename(node, name)
      ClusterContainer.where(node_id: node.id, basename: name).first
    end

    def self.get_master_by_basename(cluster, name)
      ClusterContainer.where(basename: name, cluster_id: cluster.id, node_id: nil).first
    end



    ### allocate IPs

    def self.get_ips_allocated_by_containers_in_cluster(cluster_id)
      a = ClusterContainer.w_not_deleted.where(["cluster_id = ? and node_id>0", cluster_id]).pluck(:public_ip)
      a
    end


    # return gex IP
    def self.get_private_ip_of_container(container)
      return nil if container.nil?

      if container.node
        return Gexcore::Consul::Service.get_container_primary_ip(container)
      else
        # master
        return container.private_ip
      end

      nil
    end


    # return local IP
    def self.get_public_ip_of_container(container)
      return nil if container.nil?

      if container.node
        #return container.public_ip
        return Gexcore::Consul::Service.get_container_local_ip(container)
      else
        # master
        return nil
      end

      nil
    end



    ###
=begin
    def self.update_ip_for_container(container_name, node, ip)
      row = get_by_node(container_name, node)

      row.ip = ip
      row.save

    end
=end


    def self.update_ip_for_container_node(domain, ip, data={})
      res = Response.new

      # input
      cluster_uid = data[:cluster_id]
      node_uid = data[:node_id]

      return res.set_error_badinput("update_container_ip_error", "No input") if node_uid.nil? || cluster_uid.nil?

      cluster = Cluster.get_by_uid cluster_uid
      node = Node.get_by_uid node_uid
      return res.set_error_badinput("update_container_ip_error", "Node not found") if cluster.nil? || node.nil?

      # work
      res_domain = Gexcore::Applications::Service.parse_domain(domain,node.name)
      return res.set_error_badinput("update_container_ip_error", "Bad domain") if res_domain[:container_name].nil?

      container_name = res_domain[:container_name]
      container_basename = res_domain[:container_basename]
      node_name = res_domain[:node_name]

      #
      #container = ClusterContainer.get_by_name(container_name)
      # can be multiple containers with the same name
      containers = ClusterContainer.where(cluster_id: cluster.id, node_id: node.id, name: container_name).all


      # update container data in DB
      containers.each do |container|
        #res_db = update_ip_for_container(container_name, node, ip)

        #container.public_ip = ip
        #res_update = container.save

        gex_logger.debug("update_container_ip", "IP update start", {container_id: container.id, ip: ip})

        # update in consul
        res_update = Gexcore::Consul::Service.update_container_local_ip(container, ip)


        #
        gex_logger.debug("update_container_ip", "IP updated", {container_id: container.id, ip: ip})

        if !res_update
          return res.set_error("update_container_ip_error", "Cannot update IP")
        end

      end

      #
      #res_provision = Gexcore::Provision::Service.update_container_route(node, ip)
      #if res_provision.error?
      #  return res.set_error("update_container_ip_error", "Cannot update IP", "error in provision script")
      #end

      # clear IPs for the containers with the same IP
      existing_containers = ClusterContainer.where(cluster_id: cluster.id, public_ip: ip).where.not(name: container_name).all

      existing_domains = existing_containers.map{|r| r.hostname}

      existing_containers.update_all("public_ip=''")

      gex_logger.debug("debug_update_container_ip", "IP updated")


      # invalidate cache
      Gexcore::DnsService.cache_invalidate_by_domain(domain)
      Gexcore::DnsService.cache_invalidate_by_ip(ip)

      existing_domains.each do |d|
        Gexcore::DnsService.cache_invalidate_by_domain(d)
      end


      res.set_data
    end



    def self.get_containers_list_by_user(user, filter)
      #
      cluster_uid = filter[:cluster_uid]
      cluster = Cluster.get_by_uid(cluster_uid)
      # cluster not exists
      return Response.res_error_badinput("", 'cluster not found', 'cluster not found') if cluster.nil?


      # check node belongs to this user
      #if !(user.can? :view_node_info, node)
      #  return Response.res_error_forbidden("view_containers_error", 'No permissions to view node')
      #end

      #
      return get_containers_list(cluster, filter)
    end


    def self.get_containers_list(cluster, filter)

      # node
      node_uid = filter[:node_uid]
      if node_uid
        node = Node.get_by_uid node_uid

        # node not exists
        return Response.res_error_badinput("view_containers_error", 'Node not found') if node.nil?

        # node status deleted
        return Response.res_error_badinput("view_containers_error", 'Node not found') if node.removed?
      end

      # application
      application_uid = filter[:application_uid]
      if application_uid
        application = ClusterApplication.get_by_uid application_uid

        # application not exists
        return Response.res_error_badinput("view_containers_error", 'Application not found') if application.nil?

        # application status deleted
        return Response.res_error_badinput("view_containers_error", 'Application deleted') if application.removed?
      end

      #
      q = cluster.containers.includes(:application, :node).w_not_deleted
      if node
        q = q.where(node: node)
      end

      if application
        q = q.where(application_id: application.id)
      end

      #
      rows = q.order("id desc").limit(1000)

      #
      data = rows.map{|r| r.to_hash}

      #
      return Response.res_data({containers: data })
    end



    ### callbacks

    def self.do_after_installed(container)
      #app = container.application

      # status for services
      services = container.services.all
      services.each do |service|
        service.finish_install!
      end


      #
      #container.set_active!
    end



    def self.do_after_started(container)
      # status for services
      services = container.services.all
      services.each do |service|
        # TODO: TBD
        #service.finish_install!
      end
    end



    ### status

    def self.log_status_change(container)
      gex_logger.info(
          "container_status_changed",
          "Container #{container.name}. Status changed from #{container.status_name(container.aasm.current_state)} to #{container.status_name(container.aasm.to_state)}",
          {
              container_id: container.id,
              #uid: container.uid,
              from: container.aasm.current_state,
              to: container.aasm.to_state,
              event: container.aasm.current_event}
      )
    end



    def self.fix_status(container_or_id, old_status, new_status)
      res = Gexcore::Response.new

      # input
      if container_or_id.is_a? Node
        container = container_or_id
      else
        container = ClusterContainer.get_by_id(container_or_id)
      end

      if container.nil?
        return res.set_error('container_status_change', 'container not found')
      end

      #
      res.sysdata[:container_id] = container.id

      if container.status.to_s == old_status
        res_event = container.send(:"set_#{new_status.to_s}!")

        if !res_event
          return  Response.res_error("container_change_status_error", 'Cannot change container status',"error changing status: status=#{new_status} ")
        end

        return res
      end

      return res.set_data
    end






  end
end

