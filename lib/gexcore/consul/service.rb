module Gexcore::Consul

  class Service

    ### cluster locks

    def self.get_cluster_locks(cluster_id)
      lock_names = %w(openvpn provisioner provisioner_first master proxy webproxy)

      res = {'lock_values'=>{}, 'lock_objects'=>{}}
      lock_names.each do |name|
        res['lock_values'][name] = Gexcore::Consul::Utils.consul_get_val(cluster_id, "/lock/#{name}", "0")
        res['lock_objects'][name] = Gexcore::Consul::Utils.consul_get_val_object(cluster_id, "/lock/#{name}", "0")

      end


      res
    end

    ### cluster

    def self.get_cluster_data(cluster)
      key = Gexcore::Consul::Settings.key_cluster_data(cluster.id)
      Gexcore::Consul::Utils.consul_get(cluster.id, key)
    end


    def self.set_cluster_data(cluster, data)
      key = Gexcore::Consul::Settings.key_cluster_data(cluster.id)
      Gexcore::Consul::Utils.consul_set(cluster.id, key, data)
    end


    def self.update_cluster_data(cluster, data)
      # get current data
      cluster_data = get_cluster_data(cluster)
      cluster_data ||={}

      # merge
      merge_hash!(cluster_data, data)

      # save to consul
      set_cluster_data cluster, cluster_data
    end



    ### node

    def self.get_node_data(node)
      key = Gexcore::Consul::Settings.key_node_data(node.id)
      Gexcore::Consul::Utils.consul_get(node.cluster_id, key)
    end


    def self.set_node_data(node, data)
      key = Gexcore::Consul::Settings.key_node_data(node.id)

      Gexcore::Consul::Utils.consul_set(node.cluster_id, key, data)
    end


    def self.update_node_data(node, data)
      # get current data
      node_data = get_node_data(node)
      node_data ||={}

      # merge
      merge_hash!(node_data, data)

      # save to consul
      set_node_data node, node_data
    end


    ### app

    def self.get_app_data(app)
      key = Gexcore::Consul::Settings.key_app_data(app.id)
      Gexcore::Consul::Utils.consul_get(app.cluster_id, key)
    end

    def self.set_app_data(app, data)
      key = Gexcore::Consul::Settings.key_app_data(app.id)
      Gexcore::Consul::Utils.consul_set(app.cluster_id, key, data)
    end

    def self.update_app_data(app, data)
      # get current data
      app_data = get_app_data(app)
      app_data||={}

      # merge
      merge_hash!(app_data, data)

      # save to consul
      set_app_data app, app_data
    end



    ### app settings
    def self.get_app_settings(app)
      key = Gexcore::Consul::Settings.key_app_settings(app.id)
      Gexcore::Consul::Utils.consul_get(app.cluster_id, key)
    end

    def self.set_app_settings(app, data)
      key = Gexcore::Consul::Settings.key_app_settings(app.id)
      Gexcore::Consul::Utils.consul_set(app.cluster_id, key, data)
    end

    def self.update_app_settings(app, data)
      # get current data
      app_data = get_app_settings(app)
      app_data ||= {}

      # merge
      merge_hash!(app_data, data)

      # save to consul
      set_app_settings app, app_data
    end


    ### container

    def self.get_container_data(container)
      key = Gexcore::Consul::Settings.key_container_data(container.id)
      Gexcore::Consul::Utils.consul_get(container.cluster_id, key)
    end

    def self.set_container_data(container, data)
      key = Gexcore::Consul::Settings.key_container_data(container.id)
      Gexcore::Consul::Utils.consul_set(container.cluster_id, key, data)
    end


    def self.update_container_data(container, new_data)
      # get current data
      data = get_container_data(container)
      data ||={}

      # merge
      merge_hash!(data, new_data)

      # save to consul
      set_container_data container, data
    end


    ### container properties

    def self.get_container_primary_ip(container)
      key = Gexcore::Consul::Settings.key_container_primary_ip(container)
      Gexcore::Consul::Utils.consul_get_val(container.cluster_id, key)
    end


    def self.update_container_local_ip(container, ip)
      key = Gexcore::Consul::Settings.key_container_local_ip(container)
      Gexcore::Consul::Utils.consul_set_val(container.cluster_id, key, ip)
    end

    def self.get_container_local_ip(container)
      key = Gexcore::Consul::Settings.key_container_local_ip(container)
      Gexcore::Consul::Utils.consul_get_val(container.cluster_id, key)
    end



    ### helpers
    def self.merge_hash!(h, h_new)
      h_new.each do |k, v|
        h[k] = v
      end

      h
    end
  end
end


