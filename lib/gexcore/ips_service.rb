module Gexcore
  class IpsService < BaseService

    def self.int_to_ipv4(n)
      [24, 16, 8, 0].collect {|b| (n >> b) & 255}.join('.')
    end

    def self.get_ipv6(prefix, location, cluster_id, node_number, app_number=0, container_number=0)
      "#{prefix}:#{cluster_id.to_s(16)}:#{location.to_s(16)}:#{node_number.to_s(16)}:#{app_number.to_s(16)}:#{container_number.to_s(16)}"
    end

    def self.ipv6_for_node(cluster_id, node_number)
      get_ipv6(
          config.ip_client_base,
          1, # location
          cluster_id, node_number
      )

    end

    def self.port_for_node(node_id, node_number)
      return 1024+node_id
    end

    def self.ipv6_for_node_container(cluster_id, node_number, app_number, container_number)
      get_ipv6(
          config.ip_client_base,
          1, # location
          cluster_id, node_number,
          app_number, container_number
      )
    end


  end
end

