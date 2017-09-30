module Gexcore::Applications

  class Identifier
    attr_accessor :external
    attr_accessor :cred

    def initialize(external, cred1, cred2=nil)
      @external = external
      @cred = external ? cred1 + ':' + cred2 : cred1
    end

    def get_raw_cred
      if @external
        @cred.split(':')
      else
        @cred
      end
    end

  end

end