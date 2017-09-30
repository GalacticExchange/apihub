
# for .log to json
class MySimpleFormatter < ActiveSupport::Logger::SimpleFormatter
  def call(severity, timestamp, _progname, message)
    d = {
        level: severity,
        datetime: timestamp.getutc,
        #source: 'rails',
        #host: 'karlovich',
        #log_type: 'rails_log',
        message: message
    }.to_json + "\n"
  end
end