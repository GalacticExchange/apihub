module Gexcore::Locks
  class Manager < Gexcore::BaseService

    def self.lock(resource, ttl=60, opts={})
      $lock.lock(resource, ttl, opts)
    end
  end
end

