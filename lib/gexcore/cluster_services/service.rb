module Gexcore::ClusterServices

  class Service < Gexcore::BaseService

    ### create row in DB

    def self.create_service(service_name, app, container, data={})
      # library
      #service = ClusterService.find_by(name: service_name)
      #return false if service.nil?

      #
      row = ClusterService.new(name: service_name, application_id: app.id, container_id: container.id, node_id: container.node_id )

      # port_in: service.port
      data.each do |f, v|
        row[f] = v
      end

      #
      lib_serv = LibraryService.get_by_name(service_name)
      lib_serv_title = lib_serv.title if lib_serv
      row.title = lib_serv_title || service_name

      #
      if lib_serv
        row.type_name = lib_serv.type.name
      else
        row.type_name = 'custom'
      end


      #
      row.public_ip ||= container.get_public_ip
      row.private_ip ||= container.get_private_ip


      res = row.save

      return nil if !res

      #
      row.begin_install!

      #
      row.id
    end

    def self.update_service(service, data={})
      row = service
      data.each{ |f, v| row[f] = v }
      res = row.save

      res
    end

    def self.remove_service(service)
     service.set_removed!
    end



    ###

    def self.get_port_for_service(cluster, service_name)
      #service = ClusterService.find_by(name: service_name)
      #return false if service.nil?

      #ClusterService.where(cluster_id: cluster.id, service_id: service.id).first
      ClusterService.where(name: service_name, cluster_id: cluster.id).first
    end

    def self.get_ports_by_service(cluster)
      a = ClusterService.where(cluster_id: cluster.id).all

      res = {}
      a.each {|item| res[item.name]=item}
      #a.inject({}) { |hash, item| hash.merge!}

      res
    end


    ###
=begin
    def self.get_services_info_by_user(user, cluster_uid, node_uid)
      #
      cluster = Cluster.get_by_uid(cluster_uid)

      # cluster not exists
      return Response.res_error_badinput("", 'cluster not found', 'cluster not found') if cluster.nil?

      # check permissions
      if !(user.can? :view_service_info, cluster)
        return Response.res_error_forbidden("view_service_error", 'No permissions to view service')
      end

      # node
      node = nil
      if node_uid.present? && !node_uid.blank?
        node = Node.get_by_uid node_uid

        if node.nil?
          return Response.res_error_badinput("view_service_error", 'Node not found')
        end


        # check node belongs to this user
        if !(user.can? :view_node_info, node)
          #node = nil
          return Response.res_error_forbidden("view_service_error", 'No permissions to view node')
        end
      end


      return get_service_info(cluster, node)
    end


    ###
    #def self.get_service_info(cluster, node, service_name)
    def self.get_service_info(cluster, node)
      #mtd = :"get_service_info_#{service_name}"

      #cluster = Cluster.get_by_uid cluster_uid
      #node = Node.get_by_uid node_uid

      if cluster.nil?
        return Gexcore::Response.res_error_badinput('','Cluster not found')
      end

      #
      res_data||={}
      res_data[:name] = service_name

      service_data = send(mtd, cluster, node)
      res_data.merge!(service_data)


      #
      return Response.res_data({service: res_data })
    end


    ###

    def self.get_service_info_hadoop(cluster, node=nil)
      res = {}
      res[:master_endpoints] = Gexcore::AppHadoop.get_master_endpoints(cluster.hadoop_app)

      # node
      if node && node.present?
        res[:node_endpoints] = Gexcore::AppHadoop.get_node_endpoints(cluster.hadoop_app, node)
      end

      res
    end

=end

    ###

    def self.get_service_list_by_user(user, filter)
      #
      cluster_uid = filter[:cluster_uid]
      cluster = Cluster.get_by_uid(cluster_uid)
      # cluster not exists
      return Response.res_error_badinput("", 'cluster not found', 'cluster not found') if cluster.nil?

      filter[:cluster_id] = cluster.id

      # check permissions
      if !(user.can? :view_service_info, cluster)
        return Response.res_error_forbidden("view_service_error", 'No permissions to view service')
      end

      # node
      node = nil
      node_uid = filter[:node_uid]
      if node_uid.present? && !node_uid.blank?
        node = Node.get_by_uid node_uid

        if node.nil?
          return Response.res_error_badinput("view_service_error", 'Node not found')
        end


        # check node belongs to this user
        if !(user.can? :view_node_info, node)
          #node = nil
          return Response.res_error_forbidden("view_service_error", 'No permissions to view node')
        end

        filter[:node_id] = node.id
      end

      # app
      app = nil
      app_uid = filter[:app_uid]
      if app_uid.present? && !app_uid.blank?
        app = ClusterApplication.get_by_uid app_uid

        if app.nil?
          return Response.res_error_badinput("view_service_error", 'Application not found')
        end

        # check app belongs to this user
        if !(user.can? :view_app_info, app)
          return Response.res_error_forbidden("view_service_error", 'No permissions to view application')
        end

      end

      filter[:application_id] = app.id unless app.nil?



      # container
      cont = nil
      cont_uid = filter[:cont_uid]
      if cont_uid.present? && !cont_uid.blank?
        cont = ClusterContainer.get_by_uid cont_uid

        if cont.nil?
          return Response.res_error_badinput("view_service_error", 'Container not found')
        end

        # check container belongs to this user
        if !(user.can? :view_service_info, cont.cluster)
          return Response.res_error_forbidden("view_service_error", 'No permissions to view container')
        end

      end

      filter[:container_id] = cont.id unless cont.nil?


      return get_service_list(filter)
    end


    def self.get_service_list(filter)
      #
      q = ClusterService.w_not_deleted
      #q = cluster.services.where(name: service_name)

      q = q.where(cluster_id: filter[:cluster_id]) if filter[:cluster_id]
      q = q.where(node_id: filter[:node_id]) if filter[:node_id]
      q = q.where(application_id: filter[:application_id]) if filter[:application_id]
      q = q.where(container_id: filter[:container_id]) if filter[:container_id]
      q = q.where(type_name: filter[:services_type]) if filter[:services_type]

      #
      rows = q.includes(:container, :node).all
      data = rows.map{|r| r.to_hash}

      #
      return Response.res_data({services: data })
    end


  end
end
