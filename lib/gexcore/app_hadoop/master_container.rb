module Gexcore::AppHadoop
  class MasterContainer
    def self.config
      Gexcore::Settings
    end


    ### uid
    def self.generate_uid(container_basename, cluster)
      d = Date.today
      d.strftime('%y%j') + Gexcore::Common.random_string_digits(11)
    end


    ### IP
    def self.get_ip(container_basename, cluster)
      #return get_public_ip(container_basename, cluster)
      return get_private_ip(container_basename, cluster)
    end

    def self.get_public_ip(container_basename, cluster)
      container = Gexcore::Containers::Service.get_master_by_basename(cluster, container_basename)
      return Gexcore::Containers::Service.get_public_ip_of_container(container)
      #return Gexcore::Containers::Service.get_public_ip_of_container_master(container_basename, cluster)
    end

    def self.get_private_ip(container_basename, cluster)
      container = Gexcore::Containers::Service.get_master_by_basename(cluster, container_basename)
      return Gexcore::Containers::Service.get_private_ip_of_container(container)
      #return Gexcore::Containers::Service.get_private_ip_of_container_master(container_basename, cluster)
    end

    def self.calc_ip(container_basename, cluster)
      if container_basename=='hadoop'
        return hadoop_ip(cluster)
      elsif container_basename=='hue'
        return hue_ip(cluster)
      end

      nil
    end


    ### domain

    def self.calc_domain(container_name, cluster)
      mtd = :"#{container_name}_domain"
      if respond_to?(mtd)
        return send(mtd, cluster)
      end

      return hadoop_domain(cluster)
    end

    def self.calc_hostname(container_name, cluster)
      mtd = :"#{container_name}_hostname"
      if respond_to?(mtd)
        return send(mtd, cluster)
      end

      return hadoop_hostname(cluster)
    end

    def self.calc_domain_proxy(container_name, service)
      res = nil
      if service.protocol=='ssh'
        proxy_ip = service.cluster.get_option('proxyIP')

        if proxy_ip.present? && proxy_ip!=""
          res = proxy_ip
        end

      elsif service.protocol=='http'
        res = "p#{service.port_out}.#{config.webproxy_host}"
      end

      res
    end




    ### hadoop master
    def self.hadoop_domain(cluster)
      hadoop_hostname(cluster)+".#{config.domain_zone}"
    end
    def self.hadoop_hostname(cluster)
      "hadoop-master-#{cluster.id}"
    end
    def self.hadoop_ip(cluster)
      "#{config.hadoop_master_ip_prefix}.#{ (cluster.id / 256).to_s}.#{ (cluster.id % 256).to_s}"
    end

    ### hue master
    def self.hue_domain(cluster)
      hue_hostname(cluster)+".#{config.domain_zone}"
    end
    def self.hue_hostname(cluster)
      "hue-master-#{cluster.id}"
    end
    def self.hue_ip(cluster)
      "#{config.hue_master_ip_prefix}.#{ (cluster.id / 256).to_s}.#{ (cluster.id % 256).to_s}"
    end


  end
end

