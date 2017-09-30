module Gexcore::AppHadoop
  class SlaveContainer
    def self.config
      Gexcore::Settings
    end

    ### uid
    def self.generate_uid(container_basename, node)
      d = Date.today
      d.strftime('%y%j') + Gexcore::Common.random_string_digits(11)
    end



    ### IP

    def self.get_ip(container_basename, node)
      return get_private_ip(container_basename, cluster)
    end

    def self.get_public_ip(container_basename, node)
      container = Gexcore::Containers::Service.get_slave_by_basename(node, container_basename)
      return Gexcore::Containers::Service.get_public_ip_of_container(container)
    end

    def self.get_private_ip(container_basename, node)
      container = Gexcore::Containers::Service.get_slave_by_basename(node, container_basename)
      return Gexcore::Containers::Service.get_private_ip_of_container(container)
    end




    def self.allocate_ip(node)
      require 'ipaddr'

      #
      return nil unless node.cluster.option_static_ips?

      # ip range
      ip_start = node.cluster.get_option('networkIPRangeStart')
      ip_end = node.cluster.get_option('networkIPRangeEnd')

      #
      ip1_int = (IPAddr.new ip_start).to_i
      ip2_int = (IPAddr.new ip_end).to_i

      ips_used = Gexcore::Containers::Service.get_ips_allocated_by_containers_in_cluster(node.cluster_id)

      ips_int_used = ips_used.map{|r| (IPAddr.new(r)).to_i}
      ips_int_used.sort!

      # find first available
      a = (ip1_int..ip2_int).to_a - ips_int_used

      return nil if a.length==0

      #
      ip_new = a[0]

      Gexcore::IpsService.int_to_ipv4(ip_new)
    end


    ### domain

    def self.calc_domain(container_name, node)
      mtd = :"#{container_name}_domain"
      if respond_to?(mtd)
        return send(mtd, node)
      end

      return hadoop_domain(node)
    end

    def self.calc_hostname(container_name, node)
      mtd = :"#{container_name}_hostname"
      if respond_to?(mtd)
        return send(mtd, node)
      end

      return hadoop_hostname(node)
    end


    ###
    def self.parse_domain(domain)
      return Gexcore::Applications::Service.parse_domain(domain)
    end

    ### domains
    def self.hadoop_domain(node)
      hadoop_hostname(node)+".#{config.domain_zone}"
    end
    def self.hadoop_hostname(node)
      "hadoop-#{node.name}"
    end


    def self.hue_domain(node)
      hue_hostname(node)+".#{config.domain_zone}"
    end
    def self.hue_hostname(node)
      "hue-#{node.name}"
    end


  end
end

