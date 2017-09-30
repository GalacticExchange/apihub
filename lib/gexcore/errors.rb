module Gexcore
  class Errors
=begin
    @@errors = nil


    def self.errors
      return @@errors unless @@errors.nil?

      # load from file
      txt = File.read('data/errors.json')
      data = JSON.parse(txt, :quirks_mode => true)

      @@errors = data

    end
=end

    def self.find_by_name(name)
      #r = errors.fetch(name, nil)
      #r

      r = Rails.cache.fetch("errors:by_name:#{name}", expires_in: 24.hours) do
        Error.where(name: name).first
      end

      r
    end

  end

end
