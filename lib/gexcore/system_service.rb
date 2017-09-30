module Gexcore
  class SystemService < BaseService
    def self.servers
      {
          'api'=> server_api,
          'master'=> server_master,
          'rabbit'=> server_rabbit
      }
    end

    def self.server_api
      return {
          :name => 'server_api',
          :id => 'server_api',
          :host=>config.api_host,
      }
    end

    def self.server_master
      return {
          :name => 'server_master',
          :id => 'server_master',
          :host=>config.master_host,
      }

    end

    def self.server_rabbit
      return {
          :name => 'server_rabbit',
          :id => 'server_rabbit',
          :host=>config.rabbit_url,
      }
    end

  end
end

