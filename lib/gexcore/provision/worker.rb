module Gexcore::Provision
  class Worker

    QUEUE = 'provision_worker'

    def self.run(worker, args)

      res = Sidekiq::Client.push(
      'queue' => QUEUE,
          'retry' => false,
          'class' => worker,
          'args' => [args]
      )

      # todo
      res
    end


  end
end