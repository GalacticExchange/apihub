module Gexcore
  class OptionService < BaseSearchService


    def self.prepare_value(name, v)
      # preprocess
      opt_row = Option.get_by_name(name)

      return v if opt_row.nil?

      if opt_row.option_type=='json'
        v = JSON.parse(v) rescue v
      end

      v
    end

    def self.get_option(name)
      return Response.res_error_badinput('', 'No input') if name.nil?

      # get from cache
      v = cache_get_option(name)

      unless v.nil?
        v = OptionService::prepare_value(name, v)
        return Response.res_data({name => v})
      end

      # evaluate
      v = Settings.get_option(name)
      return Response.res_error("option_not_found", "not found in DB", "not found in DB", 404, {}) if v.nil?

      # save to cache
      if !v.nil?
        # save to cache
        Gexcore::OptionService.cache_set_option(name, v)
      end

      #
      v = OptionService::prepare_value(name, v)

      Response.res_data({name => v})
    end

=begin
    def self.set_option(name, value)
      return Response.res_error_badinput('', 'No input') if name.nil?
      # evaluate
      v = Settings.set_option(name, value)
      return Response.res_error("option_not_found", "not found in DB", "not found in DB", 404, {}) if v.nil?
      # delete from cache
      cache_del_option(name)

      Response.res_data({name => v})
    end
=end

    def self.cache_get_option(name)
      v = $redis.get(redis_key_option(name))
      return nil if v.nil?
      v.to_s
    end

    def self.cache_set_option(name, v)
      key = redis_key_option(name)
      $redis.set key, v
      ttl = (7)*24*60*60
      $redis.expire key, ttl
      true
    end

    def self.cache_del_option(name)
      v = $redis.del(redis_key_option(name))
      return nil if v.nil?
    end

    def self.cache_del_all
      keys = $redis.keys redis_key_base+'*'
      keys.each do |k|
        v = $redis.del(k)
      end
    end


    ### redis
    # option
    def self.redis_key_base
      config.redis_prefix+":option:"
    end
    def self.redis_key_option(name)
      "#{redis_key_base}#{name}"
    end

  end
end
