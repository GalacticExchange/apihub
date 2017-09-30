Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{Rails.configuration.gex_config[:redis_host]}:6379/0", namespace: "#{Rails.configuration.SITE_NAME}_#{Rails.env}_sidekiq" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{Rails.configuration.gex_config[:redis_host]}:6379/0", namespace: "#{Rails.configuration.SITE_NAME}_#{Rails.env}_sidekiq" }
end
