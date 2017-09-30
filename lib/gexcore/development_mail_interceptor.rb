module Gexcore
  class DevelopmentMailInterceptor
    def self.delivering_email(message)
      message.in_reply_to=message.to

      message.to = [Gexcore::Settings.email_debug_catch_all]

    end
  end
end
