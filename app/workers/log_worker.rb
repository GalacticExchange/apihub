class LogWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :log, :retry => 10

  def perform(version, source_name, level, msg, type_name, data)
    Gexcore::GexLogger.log_now(version, source_name, level, msg, type_name, data)

    return true
  end
end
