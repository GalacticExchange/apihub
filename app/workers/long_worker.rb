class LongWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :clusters

  def perform
=begin
    Gexcore::GexLogger.debug("debug_long_started", "started long task")

    1.upto(10) do |i|
      filename = "/projects/apihub/tmp/sidekiq_long.txt"

      #if File.exist?(filename)
      #  break
      #end

      #
      now = Time.now.utc
      Gexcore::GexLogger.debug("debug_long_async", "test #{now}")

      sleep(5)
    end

    Gexcore::GexLogger.debug("debug_long_finished", "finished long task")
=end

  # run long provision
  script = Gexcore::Provision::Service.build_cmd_cap(
      'test:long',
      "_cluster_id=0 "
  )

  res_provision = Gexcore::Provision::Service.run('test_long', script)


  return true
  end
end
