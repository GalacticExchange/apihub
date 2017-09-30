module Gexcore::Monitoring::Checks

  class Result
    attr_accessor :name, :passed, :description, :value

    #
    def initialize(_name)
      @name = _name
    end


    def set_check(description, passed)
      @description = description
      @passed = passed
    end


    def set_passed(d=nil)
      if d
        @description = d
      end

      @passed = true
    end


    def set_failed(d=nil)
      if d
        @description = d
      end

      @passed = false
    end


    def self.to_hash
      {
          name: @name,
          description: @description,
          passed: @passed,
      }
    end

    def passed?
      self.passed
    end

    def failed?
      !self.passed
    end


    # return true if ALL checks are passed
    def self.is_all_ok(checks)
      has_failed = checks.any? {|k, c| c.failed?}

      !has_failed
    end


    ### build

    # should be overriden in derived classes
    def build_from_data(data, check_info)
      @value = nil
      @passed = false

    end


    def self.build_from_sensu_check_data(sensu_check_data, check_name, check_info, env={})
      cls_check = Object.const_get("Gexcore::Monitoring::Checks::#{check_info[:class_name]}")

      res = cls_check.new(check_name)
      res.description = check_info[:title]

      if sensu_check_data.nil?
        res.set_failed
        return res
      end

      #
      res.build_from_data(sensu_check_data['check'], check_info, env)

      res
    end

    ### helpers
    def self.parse_output(data, env={})
      output = nil
      # parse output
      begin
        output = JSON.parse(data['output']) rescue data['output']
      rescue => e
        #gex_logger.exception('cannot parse counter data', e, {output: data['check']['output']})
        return nil
      end

      output
    end


  end
end

