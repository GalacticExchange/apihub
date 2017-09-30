$redis = Redis.new(:host => Rails.configuration.gex_config[:redis_host], :port => 6379)
