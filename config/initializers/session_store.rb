# Be sure to restart your server when you modify this file.

Rails.application.config.session_store :redis_store, servers: { :host => Rails.configuration.gex_config[:redis_host],
                                                                :port => 6379,
                                                                :namespace => Rails.configuration.gex_config[:redis_prefix] + ":sessions",
                                                   },
                                       :expires_in => 30.days
