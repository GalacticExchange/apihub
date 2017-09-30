$lock = Redlock::Client.new([ "redis://#{Rails.configuration.gex_config[:redis_host]}:6379"])
