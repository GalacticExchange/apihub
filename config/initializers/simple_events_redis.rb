require 'events'

$Mylog = SimpleEventsRedis::Events

$Mylog.this_site_name = (Rails.env.beta? ? 'test_' : '')+Rails.application.config.SITE_NAME
$Mylog.set_config({:EXPIRE_DAYS => 4})

