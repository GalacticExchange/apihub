module Gexcore
  class Settings < BaseService

    VERSION = "0.2.1"
    CLIENT_MIN_SUPPORTED_VERSION = "0.7.0"

    ### current IP

    @@current_ip = ''
    def self.ip
      @@current_ip
    end

    def self.ip=(v)
      @@current_ip = v
    end

    def self.gex_env
      Rails.configuration.gex_env
    end

    def self.gex_config
      Rails.configuration.gex_config
    end

    def self.method_missing(method_sym, *arguments, &block)
      gex_config[method_sym] || gex_config[method_sym.to_s]
    end


    ### provision
    def self.provision_env
      gex_config[:provision_env]
    end

    def self.provision_basedir
      gex_config[:provision_scripts_dir]+''
    end

    def self.provisioner_dir
      File.join(provision_basedir,'provisioner')
    end


    def self.ansible_inventory
      e = provision_env
      res = 'inventory'
      res = 'inventory' if e
      res = 'devinventory' if e=='development'
      res = 'prodinventory' if e=='production'
      provision_basedir+res
    end



    ### servers IPs
    def self.domain_zone
      gex_config[:domain_zone]
    end

    ### options
    def self.get_option(name, v_def=nil)
      if respond_to?("get_option_#{name}")
        data = send "get_option_#{name}"
      else
        data = Option.get(name, v_def)
      end
      return data
    end

    def self.set_option(name, v)
      data = Option.set(name, v)
      return data
    end

    def self.get_option_api_version
      VERSION
    end

    # min supported version ruby-client
    def self.get_client_min_supported_version
      CLIENT_MIN_SUPPORTED_VERSION
    end


    ### emails

    def self.email_from_full
      "\"Galactic Exchange\" <#{email_from}>"
    end

  end
end


