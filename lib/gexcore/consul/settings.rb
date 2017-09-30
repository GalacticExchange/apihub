module Gexcore::Consul

  class Settings

    def self.consul_url(cluster_id)
      port = consul_ports(cluster_id)[:http]
      "http://#{Gexcore::Settings.openvpn_private_ip}:#{port}"
    end

    def self.consul_ports(cluster_id)
      max = cluster_id.to_i * 5
      arr = (max).downto(max-4).to_a
      {
          dns: 40000 + arr[0],
          http: 40000 + arr[1],
          serf_lan: 40000 + arr[2],
          serf_wan: 40000 + arr[3],
          server: 40000 + arr[4]
      }
    end

    ### key
    def self.key_prefix
      '/v1/kv/'
    end

    def self.build_key(k)
      k.gsub! /^\//, ''
      File.join(key_prefix, k)
    end
    def self.key_cluster_data(cluster_id=nil)
      'info/cluster_data.json'
    end
    def self.key_node_data(node_id)
      "nodes/id/#{node_id}/node_data.json"
    end

    def self.key_app_data(app_id)
      "apps/id/#{app_id}/app_data.json"
    end
    def self.key_app_settings(app_id)
      "apps/id/#{app_id}/app_settings.json"
    end

    def self.key_container_data(id)
      "containers/id/#{id}/container_data.json"
    end

    def self.key_container_primary_ip(container)
      "nodes/#{container.node.name}/containers/#{container.basename}/primary_ip"
    end

    def self.key_container_local_ip(container)
      "containers/#{container.id}/local_ip"
    end

  end

end
