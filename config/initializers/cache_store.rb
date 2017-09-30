=begin
Rails.application.config.cache_store = :redis_store, {
    host: Rails.configuration.gex_config[:redis_host],
    port: 6379,
    namespace: Rails.configuration.gex_config[:redis_prefix]+":cache"
    #db: 0,
    #password: "mysecret",
}


=end
