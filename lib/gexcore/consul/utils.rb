module Gexcore::Consul

  class Utils < ::Gexcore::BaseService
    def self.consul_get(cluster_id, key_data)
      u = Gexcore::Consul::Settings.consul_url(cluster_id)
      key = Gexcore::Consul::Settings.build_key(key_data)

      conn = Faraday.new(:url => u)

      response = conn.get "#{key}?raw"

      v = JSON.parse(response.body) rescue nil

      return v
    rescue => e
      gex_logger.debug('consul_error', 'error in consul', {cluster_id: cluster_id, e: e})

      return nil
    end


    def self.consul_get_val(cluster_id, k, v_def=nil)
      u = Gexcore::Consul::Settings.consul_url(cluster_id)
      key = Gexcore::Consul::Settings.build_key(k)

      conn = Faraday.new(:url => u)

      response = conn.get "#{key}?raw"
      v = response.body rescue nil

      return v
    rescue => e
      v = v_def

      gex_logger.debug('consul_error', 'error in consul', {cluster_id: cluster_id, e: e})

      return v
    end


    def self.consul_get_val_object(cluster_id, k, v_def=nil)
      u = Gexcore::Consul::Settings.consul_url(cluster_id)
      key = Gexcore::Consul::Settings.build_key(k)

      conn = Faraday.new(:url => u)

      response = conn.get "#{key}"
      v = response.body rescue nil

      return v
    rescue => e
      v = v_def

      gex_logger.debug('consul_error', 'error in consul', {cluster_id: cluster_id, e: e})

      return v
    end



    def self.consul_set(cluster_id, key, data)
      u = Gexcore::Consul::Settings.consul_url(cluster_id)
      key = Gexcore::Consul::Settings.build_key(key)

      conn = Faraday.new(:url => u)

      response = conn.put "#{key}", data.to_json

      return true
    rescue => e
      gex_logger.debug('consul_error', 'cannot save to consul', {cluster_id: cluster_id, e: e})

      return false
    end


    def self.consul_set_val(cluster_id, k, v)
      u = Gexcore::Consul::Settings.consul_url(cluster_id)
      key = Gexcore::Consul::Settings.build_key(k)

      conn = Faraday.new(:url => u)

      response = conn.put "#{key}", v

      return true
    rescue => e
      gex_logger.debug('consul_error', 'error in consul', {cluster_id: cluster_id, e: e})

      return false
    end


  end
end

