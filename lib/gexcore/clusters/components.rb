# Cluster components - it's a set of big data frameworks which
# could be installed on the master and slave nodes.
module Gexcore::Clusters

  Component = Struct.new(:id, :name, :title, :description, :version, :default, :depends_on) do
    def to_hash_full
      {
        id: id,
        name: name,
        title: title,
        description: description,
        version: version,
        default: default,
        depends_on: depends_on,
      }
    end
  end

  class Components

    COMPONENTS = [
        # :id, :name, :title, :description, :version, :default, :depends_on
        [1, 'hdfs', 'HDFS', 'A distributed file-system that stores data', '2.6.0', true, [] ],
        [2, 'kudu', 'Kudu', 'Column-oriented data store, an alternative to AWS RedShift', '1.3.0', true, [:impala, :hive] ],
        [3, 'impala', 'Impala', 'SQL analytics engine for Kudu and HDFS', '2.8.0', true, [] ],
        [4, 'hive', 'Hive', 'Older, slower SQL analytics engine', '1.1.0', true, [] ],
        [5, 'kafka', 'Kafka', 'Distributed streaming platform', '10.1.1', true, [:zookeeper] ],
        [6, 'elasticsearch', 'Elasticsearch', 'Search engine with visualization dashboards', '2.4.5', true, [] ],
        [7, 'neo4j', 'Neo4j', 'Graph database', '3.1.4', true, [] ],
        [8, 'nifi', 'NiFi', 'Easy data ingestion, routing and transformation pipelines', '1.1.2', true, [:zookeeper] ],
        [9, 'yarn', 'YARN', 'Cluster resource manager, can be used by Hive, Impala and Spark', '2.6.0', true, [] ],
        [10, 'cassandra', 'Cassandra', 'Fast distributed database', '3.0.9', true, [] ],
        [11, 'spark', 'Spark', 'In-memory parallel  data processing engine', '2.0', true, [] ],
        [12, 'zookeeper', 'ZooKeeper', 'Open-source coordination service for distributed applications.', '3.4.5-cdh5.11.0', true, [] ],
        [13, 'metabase', 'Metabase', 'Data analytics platform', '0.24.2', true, [] ],
        [14, 'superset', 'Superset', 'Data exploration platform designed to be visual, intuitive, and interactive', '0.18.4', true, [] ],
    ]



    def self.get_all_components_names
      get_components_hash.map{|c| c[:name]} rescue {}
    end

    def self.get_components_obj
      components = []
      COMPONENTS.each do |comp|
        components.push(Gexcore::Clusters::Component.new(comp[0], comp[1], comp[2], comp[3], comp[4], comp[5]))
      end
      components
    end

    def self.get_components_hash
      components_hash = []
      get_components_obj.each do |comp|
        components_hash.push(comp.to_hash_full)
      end
      components_hash
    end


    def self.get_by_id(id)
      get_components.find {|c| c.id == id }
    end

    def self.get_by_name(name)
      get_components.find {|c| c.name == name }
    end




    ### for cluster

    def self.get_cluster_components_by_user(cluster_uid, user)

      res  = Gexcore::Response.new
      cluster = Cluster.get_by_uid(cluster_uid)

      # cluster not exists
      return res.set_error_badinput("", 'cluster not found', 'cluster not found') if cluster.nil?

      # check permissions
      if !(user.can? :view_cluster_info, cluster)
        return res.set_error_forbidden("view_cluster_error", 'No permissions to view this cluster')
      end

      get_cluster_components_all(cluster, res)
    end


    def self.get_enabled_cluster_components(cluster, res)
      components = cluster.get_option('components')
      if components.nil?
        return res.set_error('cannot load cluster components', 'cannot load cluster components')
      end
      res.set_data({components: components})
    end


    def self.get_cluster_components_all(cluster, res)
      cluster_components = cluster.get_option('components')
      if cluster_components.nil?
        return res.set_error('cannot load cluster components', 'cannot load cluster components')
      end

      all_components = get_components_hash

      components = []
      all_components.each do |comp|
        enabled = cluster_components.include?(comp[:name])
        components << {name: comp[:name], enabled: enabled}
      end

      res.set_data({components: components})
    end


  end
end

