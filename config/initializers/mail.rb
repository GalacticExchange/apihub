if %w( development main).include?(Rails.env)
  #require_relative '../lib/gexcore/development_mail_interceptor'
  ActionMailer::Base.register_interceptor(Gexcore::DevelopmentMailInterceptor)
end


=begin
if %w( development test).include?(Rails.env)
  # test email - SMTP + Redis
  require 'test_email_redis/test_mail_smtp_delivery'
  ActionMailer::Base.add_delivery_method :my_test_delivery, TestEmailRedis::TestMailSmtpDelivery
  Rails.application.config.action_mailer.delivery_method = :my_test_delivery
end
=end
