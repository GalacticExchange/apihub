=begin
unless (Rails.env.test? && Rails.env.development?)
  Devise::Async.setup do |config|
    config.enabled = true
    config.backend = :sidekiq
    config.queue   = :"#{Rails.configuration.SITE_NAME}_#{Rails.env}_mailers"
    #config.queue   = :default

  end
end

=end
