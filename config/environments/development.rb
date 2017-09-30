Rails.application.configure do
  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # assets
  #config.serve_static_files = true
  config.public_file_server.enabled = true
  #config.public_file_server.enabled = false
  config.assets.debug = true
  config.assets.digest = true
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true


  # active job
  #config.active_job.queue_adapter = :sidekiq # inline sidekiq
  config.active_job.queue_adapter = :inline

  #config.active_job.queue_name_prefix = "#{Rails.configuration.SITE_NAME}"
  #config.active_job.queue_name_delimiter = "_"

  # action mailer
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  #
  #require_relative '../../lib/gexcore/development_mail_interceptor'
  #ActionMailer::Base.register_interceptor(Gexcore::DevelopmentMailInterceptor)

  # test email - SMTP + Redis
  #require 'test_email_redis/test_mail_smtp_delivery'
  #ActionMailer::Base.add_delivery_method :my_test_delivery, TestEmailRedis::TestMailSmtpDelivery
  #config.action_mailer.delivery_method = :my_test_delivery

  #
  #config.action_mailer.delivery_method = :smtp

  # gex_config
  #config.gex_env = ENV['gex_env'] || 'main'
  config.gex_env = 'main'

  ### logs
  # this allow see .log from info to emergency
  #config.log_level = :info

  # delete rendering logs
  config.action_view.logger = nil

  # construct json string
  #config.log_formatter = MySimpleFormatter.new





end
