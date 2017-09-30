module Gexcore::Applications
  class ConfigService

    # properties manageable by this service
    PROPERTIES = {
        "master.host" => {},
        "master.ip" => {},
        "master.ssh.user" => {},
        "master.ssh.password" => {},
    }


    ### env
    def self.build_env(app, user, cluster, node)
      res = {
         app: app,
         user: user,
         cluster: cluster,
         node: node,
      }

      res

    end

    ### properties

    def self.init_property_values(config, env)

      config.properties.each do |name, v|
        if v =~ /^\{\{(.*)\}\}$/
          prop_name = $1
          config.set_property_value(name, get_property_value(prop_name, env))
        end
      end
    end

    ###

    def self.get_property_value(name, env)
      s = name.gsub /\./, '_'
      mtd = :"calc_#{s}"
      if Gexcore::Applications::ConfigService.respond_to?(mtd)
        return Gexcore::Applications::ConfigService.send(mtd, env)
      end

      nil
    end

    ### values

    ## common
    def self.master_host(env)
      cluster = env[:cluster]
      container = cluster.get_master_container_hadoop
      return container.hostname
    end



    ### neo4j

    def self.hadoop_on_node(env)
      node = env[:node]
      node.get_container_hadoop
    end

    def self.calc_neo4j_host(env)
      container = hadoop_on_node(env)
      return nil if container.nil?
      container.hostname
    end

    def self.calc_neo4j_port(env)
      #container = hadoop_on_node(env)
      #return nil if container.nil?
      #neo_service = container.services.get_by_name_and_node('neo4j', env[:node])
      #neo_service.port_out

      #Gexcore::AppHadoop::App::SERVICES_SLAVE['neo4j'][:port]
      7687
    end


    ### hadoop master node
    def self.calc_master_host(env)
      cluster = env[:cluster]

      container = cluster.get_master_container_hadoop

      return container.hostname
    end

    def self.calc_master_ip(env)
      cluster = env[:cluster]
      container = cluster.get_master_container_hadoop
      return container.get_public_ip
    end

    ### zookeeper
    def self.calc_zookeeper_url(env)
      return calc_zookeeper_host(env)+":"+calc_zookeeper_port(env)
    end

    def self.calc_zookeeper_host(env)
      cluster = env[:cluster]
      container = cluster.get_master_container_hadoop
      return container.hostname
    end

    def self.calc_zookeeper_port(env)
      "2181"
    end


    ### hdfs
    def self.calc_hdfs_url(env)
      return calc_hdfs_host(env)+":"+calc_hdfs_port(env)
    end

    def self.calc_hdfs_host(env)
      cluster = env[:cluster]
      container = cluster.get_master_container_hadoop
      return container.hostname
    end

    def self.calc_hdfs_port(env)
      "8020"
    end


    ### cassandra

    def self.calc_kudu_master_host(env)
      node = env[:node]
      host = nil

      begin
        if node
          master_hadoop = node.cluster.get_master_container('hadoop')
          host = master_hadoop.hostname

          #container_hadoop = node.get_container_by_name('hadoop')
          #host = container_hadoop.hostname
        end
      rescue => e

      end

      return host
    end


    ### kafka
    def self.calc_kafka_host(env)
      cluster = env[:cluster]
      node = env[:node]

      host = nil

      begin
        if node
          container_hadoop = node.get_container_by_name('hadoop')
          #service_es = container_hadoop.services.where(name: 'elastic').first
          host = container_hadoop.hostname
        else
          container_hadoop = cluster.get_master_container_hadoop
          return container_hadoop.hostname
        end
      rescue => e

      end

      host
    end


    def self.calc_kafka_broker(env)
      calc_kafka_host(env)+":9092"
    end


    def self.calc_kafka_master_host(env)
      cluster = env[:cluster]
      container = cluster.get_master_container_hadoop
      return container.hostname
    end

    def self.calc_kafka_master_broker(env)
      calc_kafka_master_host(env)+":9092"
    end



    ### elasticsearch

    def self.calc_elasticsearch_host(env)
      node = env[:node]
      host = nil

      begin
        if node
          container_hadoop = node.get_container_by_name('hadoop')
          #service_es = container_hadoop.services.where(name: 'elastic').first
          host = container_hadoop.hostname
        end
      rescue => e

      end



      return host
    end

    def self.calc_elasticsearch_ip(env)
      node = env[:node]
      ip = nil

      begin
        if node
          container_hadoop = node.get_container_by_name('hadoop')
          ip = Gexcore::Containers::Service.get_private_ip_of_container(container_hadoop)
        end
      rescue => e

      end

      return ip
    end


    ### cassandra

    def self.calc_cassandra_host(env)
      node = env[:node]
      host = nil

      begin
        if node
          container_hadoop = node.get_container_by_name('hadoop')
          host = container_hadoop.hostname
        end
      rescue => e

      end

      return host
    end

    def self.calc_cassandra_ip(env)
      node = env[:node]
      ip = nil

      begin
        if node
          container_hadoop = node.get_container_by_name('hadoop')
          ip = Gexcore::Containers::Service.get_private_ip_of_container(container_hadoop)
        end
      rescue => e

      end

      return ip
    end


    ## solr
    def self.calc_solr_events_repo(env)
      #quickstart.cloudera:2181/solr
      cluster = env[:cluster]
      container = cluster.get_master_container_hadoop
      host = container.hostname
      return "#{host}:2181/solr"
    end




    ## hive
    def self.calc_hive_host(env)
      master_host(env)
    end

    def self.calc_hive_port(env)
      "9083"
    end



    ## impala
    def self.calc_impala_host(env)
      master_host(env)
    end

    def self.calc_impala_port(env)
      "21050"
    end


    def self.calc_cluster_name(env)
      env[:cluster].name
    end

    def self.calc_cluster_uid(env)
      env[:cluster].uid
    end


  end
end
