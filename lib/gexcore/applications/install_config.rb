module Gexcore::Applications
  class InstallConfig

    def self.config
      Gexcore::Settings.config
    end

    def initialize(_app_name)
      @app_name = _app_name
    end


    ### metadata

    def get_binding
      return binding()
    end

    def config_params(opts)
      @props_metadata = opts
    end

    #
    def props_metadata
      @props_metadata ||= {}

      @props_metadata
    end



    def properties
      return @props unless @props.nil?

      # init default
      @props = {}
      props_init_default_values

      #
      @props
    end

    def set_property_value(name, v)
      @props[name] = v

    end

    def props_init_default_values
      props_metadata.each do |name, prop_metadata|
        v = prop_metadata['default_value'] || prop_metadata[:default_value]
        @props[name.to_sym] = v
      end
    end


    def props_init_default_values_new
      props_metadata.each do |conf_gr_name, conf_group|
        @props[conf_gr_name] = {}
        conf_group.each do |container_name, container|
          @props[conf_gr_name][container_name] = {}
          container.each do |prop_name, prop|
            v = prop['default_value'] || prop[:default_value]
            @props[conf_gr_name][container_name][prop_name] = v
          end
        end
      end
    end


    def build_properties(env)
      @props = {}
      props_init_default_values
      Gexcore::Applications::ConfigService.init_property_values(self, env)

    end

    def build_properties_new(env)
      @props = {}
      props_init_default_values_new
      Gexcore::Applications::ConfigService.init_property_values(self, env)

    end


    ### init from metadata

    def init_from_metadata(app_metadata)

      # todo: tree to plain here
      attributes_tree = app_metadata.get_attributes

      @props_metadata = app_metadata.get_attributes
      @app_info = app_metadata.get_app_info
      @services = app_metadata.get_services
    end


    ### init from metadata old

    def init_from_metadata_old(app_metadata)
      @props_metadata = app_metadata.get_config_params
    end





    ###

    def config_to_plain
      # hash to plain list of options
      res = {}

      res = Gexcore::Applications::InstallConfig.build_array_from_hash('', @config)
      #a = {master: {p1: '111', p2: '222'}}
      #res = Gexcore::Applications::InstallConfig.build_array_from_hash('', a)

      res
    end




    ### helpers


    def self.build_array_from_hash(prefix, hash)
      res = {}
      hash.each do |k,v|
        if !v.is_a?(Hash)
          res[prefix+k.to_s] = v
          next
        end

        new_prefix = prefix+k.to_s+'.'

        res = res.merge(build_array_from_hash(new_prefix, v))
      end

      res
    end


    def self.build_tree_from_plain(config_hash)
      res = {}

      config_hash.each do |k, v|
        #
        a_k = k.split /\./
        current_node = res

        if a_k.length>1
          0.upto(a_k.length-2) do |i|
            pk = a_k[i]
            if !current_node.has_key?(pk)
              current_node[pk] = {}
            end

            # next
            current_node = current_node[pk]
          end

        end

        current_node[a_k.last] = v


      end

      res
    end


    ### helpers

    def is_prop_visible(name)
      p = @props_metadata[name]
      return true if p[:visible].nil?

      v = p[:visible].to_s == "1"
      v
    end

    def is_prop_editable(name)
      p = @props_metadata[name]
      if p[:editable].nil?
        v = true
      else
        v = p[:editable].to_s == "1"
      end

      v
    end

  end
end
