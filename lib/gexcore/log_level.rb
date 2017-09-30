module Gexcore
  class LogLevel
    attr_accessor :id, :name, :title

    # levels
    TRACE = 'trace'
    DEBUG = 'debug'
    INFO = 'info'
    WARNING = 'warning'
    ERROR = 'error'
    CRITICAL = 'critical'

    LEVELS = { TRACE => 1, DEBUG => 2, INFO => 3, WARNING => 4, ERROR => 5, CRITICAL => 6}
    LEVELS_BY_ID = LEVELS.invert

    def initialize(_id, _name)
      @id = _id
      @name = _name
    end

    def self.get_all
      res = []
      LEVELS.each do |name, v|
        res << LogLevel.new(v, name)
      end

      res
    end

    def self.get_all_with_blank
      res = get_all
      res.unshift(LogLevel.new(0, 'ALL'))

    end
  end
end
