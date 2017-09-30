module Gexcore::Containers
  class Container < Gexcore::BaseService

    ### create
    def self.create_container_master(container_name, app, cluster, data={})
      # add to DB
      hash = {name: container_name, cluster_id: cluster.id, application_id: app.id, node_id: nil, is_master: true}
      data.each{|f, v| hash[f] = v}

      row = ClusterContainer.new(hash)
      res = row.save

      return nil if !res

      row.id
    end

    def self.create_container_on_node(container_basename, container_name, app, node, fields_data={})
      #container = ClusterContainer.get_by_name(container_name)
      #return nil if container.nil?

      # add to DB
      uid = Gexcore::TokenGenerator::generate_container_uid
      hash = {
          uid: uid,
          basename: container_basename,
          name: container_name,
          application_id: app.id,
          node_id: node.id,
          is_master: false
      }
      fields_data.each{|f, v| hash[f] = v}
      row = ClusterContainer.new(hash)
      res = row.save

      return nil if !res

      row.id
    end


    def self.remove_container(container)
      # delete services for the container
      container.services.w_not_deleted.all.each do |service|
        Gexcore::ClusterServices::Service.remove_service(service)
      end


      # delete container itself
      container.set_removed!
    end

  end
end
