module Gexcore
  class ClusterInfoService < BaseService

    def self.get_node_property_vpn(node, property_name)
      #/var/www/data/clusters/99/vpn/3_4_node_client_ip
      #/var/www/data/clusters/99/vpn/99_4_node_server_ip
      #/var/www/data/clusters/99/vpn/99_4_node_port

      begin
        f = filename_node_property_vpn(node, property_name)
        s = File.read(f)
        s.strip!
      rescue Exception =>e
        return nil
      end


      if !File.exists?(f)
        return nil
      end

      return s
    end

    def self.filename_node_property_vpn(node, property_name)
      "#{Gexcore::Settings.dir_clusters_data}#{node.cluster_id}/vpn/#{node.cluster_id}_#{node.node_number}_node_#{property_name}"
    end
  end
end

