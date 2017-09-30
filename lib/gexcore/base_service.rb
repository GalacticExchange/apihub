module Gexcore
  class BaseService


    ## response
    Response = Gexcore::Response

    def self.response_init(sysdata={})
      res = Gexcore::Response.new
      res
    end

    ###

    def self.gex_logger
      Gexcore::GexLogger
    end

    def self.config
      Gexcore::Settings
    end


    def self.get_env
      res = {}

      res[:ip] = Gexcore::Settings.ip

      res
    end

    def self.set_env(sysdata)
      Gexcore::Settings.ip = sysdata[:ip] || sysdata['ip']

      true
    end


    def self.make_hub_link(u)
      config.hub_url + u
    end

  end
end

