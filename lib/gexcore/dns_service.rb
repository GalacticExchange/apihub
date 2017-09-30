module Gexcore
  class DnsService < BaseService

    def self.get_ip_by_domain(domain)
      return Response.res_error_badinput('', 'No input') if domain.nil?

      # get from cache
      ip = cache_get_domain_ip(domain)

      unless ip.nil?
        return Response.res_data({ip: ip})
      end

      # evaluate
      ip = ip_by_domain(domain)

      # save to cache
      if !ip.nil?
        # save to cache
        cache_set_domain_ip(domain, ip)
      end

      Response.res_data({ip: ip})
    end


    def self.get_domain_by_ip(ip)
      return Response.res_error_badinput('', 'No input') if ip.nil?

      # get from cache
      v = cache_get_domain_by_ip(ip)

      unless v.nil?
        return Response.res_data({domain: v})
      end

      # evaluate
      v = domain_by_ip(ip)

      # save to cache
      if !v.nil?
        # save to cache
        cache_set_domain_by_ip(ip, v)
      end

      Response.res_data({domain: v})
    end


    ### domains, ips

    ### resolve domain to IP
    def self.ip_by_domain(domain)
      zone = config.domain_zone

      ip = nil

      # check zone
      if !(domain =~ /^(.*?)\.#{zone}$/i)
        ip = nil
        return ip
      end

      hostname = $1

      res_master = parse_master_hostname(hostname)
      if !(res_master.nil?)
        service_name, p_cluster = res_master

        #gex_logger.debug "s: #{service_name}, #{p_cluster}",

        if p_cluster =~ /^\d+$/
          cluster = Cluster.get_by_id p_cluster
        else
          cluster = Cluster.get_by_name p_cluster
        end

        unless cluster.nil?
          ip = Gexcore::AppHadoop::MasterContainer.get_ip(service_name, cluster)
        end

      end

      # parse as node
      if ip.nil?
        res_node = parse_node_hostname(hostname)

        if !res_node.nil?
          service_name, p_node = res_node
          node = Node.get_by_name p_node
          unless node.nil?
            ip = Gexcore::AppHadoop::SlaveContainer.get_ip(service_name, node)
          end
        end

      end



      ip
    end

    ### resolve IP to domain
    def self.domain_by_ip(ip)
      return nil if ip.nil?

      domain = nil

      # container
      container = ClusterContainer.get_by_ip ip

      if container
        #domain = Gexcore::ClusterServices::Service.calc_domain_of_container(container)
        domain = container.domainname
      end
      return domain unless domain.nil?


      domain
    end


    ### parse domain

    def self.parse_master_hostname(hostname)
      if hostname =~ /^([a-z]+)-(master)-(\d+|[a-z\-]+)$/i
        service_name, p_cluster = $1, $3
      else
        return nil
      end

      return [service_name, p_cluster]
    end

    def self.parse_node_hostname(hostname)
      if hostname =~ /^([a-z]+)-([a-z\-]+)$/i
        service_name, p_node = $1, $2
      else
        return nil
      end

      return [service_name, p_node]
    end





    ### cache for DNS

    def self.cache_get_domain_ip(domain)
      v = $redis.get(redis_key_ip_by_domain(domain))
      return nil if v.nil?
      v.to_s
    end

    def self.cache_set_domain_ip(domain, ip)
      key = redis_key_ip_by_domain(domain)
      $redis.set key, ip
      ttl = (30)*24*60*60
      $redis.expire key, ttl
      true
    end

    def self.cache_invalidate_by_domain(domain)
      $redis.del(redis_key_ip_by_domain(domain))
    end


    def self.cache_get_domain_by_ip(ip)
      v = $redis.get(redis_key_domain_by_ip(ip))
      return nil if v.nil?
      v.to_s
    end


    def self.cache_set_domain_by_ip(ip, domain)
      key = redis_key_domain_by_ip(ip)
      $redis.set key, domain
      ttl = (30)*24*60*60
      $redis.expire key, ttl
      true
    end

    def self.cache_invalidate_by_ip(ip)
      $redis.del(redis_key_domain_by_ip(ip))
    end



    ### redis
    def self.redis_key_ip_by_domain(domain)
      config.redis_prefix+":dns:ips:#{domain}"
    end
    def self.redis_key_domain_by_ip(ip)
      config.redis_prefix+":dns:domains:#{ip}"
    end
  end
end
