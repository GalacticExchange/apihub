module Gexcore
  class Response
    attr_accessor :res, :data, :http_status, :sysdata,
                  :error_name, :error_code, :error_msg, :error_desc, :error_data, :errors,
                  :sys_error_msg, :sys_error_desc


    def http_status
      @http_status ||= 200

      @http_status
    end

    def success?
      return res
    end

    def error?
      return !res
    end

    def has_data?
      return !(data.empty?)
    end

    def error_code
      return 0 if @error_code.nil?
      @error_code
    end

    def data
      @data ||= {}
      @data
    end

    def sysdata
      @sysdata ||= {}
      @sysdata
    end

    def error_msg_human
      if errors.present? && errors.length>0
        s = errors[0][:message] || ''
        msg = s unless s.blank?
      end

      msg ||= self.error_msg

      msg
    end


    # downcase
    def error_name_small
      error_name.downcase
    end

    def error_name_upcase
      error_name.upcase rescue nil
    end

    ###

    def get_error_data
      {'code'=>error_code, 'errorname'=>error_name_upcase, 'message'=>error_msg || '', 'description'=>error_desc || '', 'errors'=>errors}
    end


    def set_error(name, err_msg, err_msg_sys=nil, http_status=nil, _sysdata={})
      self.res = false

      #
      self.http_status = http_status || 500

      # main error
      self.error_name = name
      err = Errors.find_by_name(name)
      #is_err_general = err.nil?
      err = Errors.find_by_name('general') if err.nil?

      if err
        self.error_name = name.upcase
        self.error_code = err.id
        self.error_msg = err.title
        self.error_desc = err.description || ''
      end


      # errors array
      self.errors ||= []
      #self.errors = []
      add_error_message err_msg

      # sys_msg
      self.sys_error_msg = err_msg_sys unless err_msg_sys.nil?
      self.sys_error_msg ||= ''

      #
      add_sysdata(_sysdata)

      #
      self
    end

    def set_error_badinput(error_name, msg, msg_sys='')
      set_error error_name, msg, msg_sys, 400
    end
    def set_error_forbidden(error_name, msg, msg_sys='')
      error_name = 'forbidden' if error_name.empty?
      set_error error_name, msg, msg_sys, 403
    end
    def set_error_exception(msg, exception)
      self.sysdata[:exception] = {message: exception.message, backtrace: exception.backtrace.inspect}
      set_error('exception', msg, "Exception: #{exception.message}", 500)
    end

    def set_data(_data={})
      self.res = true
      self.data = _data

      #
      self
    end

    ###

    def add_error_message(msg)
      self.errors ||= []

      return if msg.blank?

      self.errors << ({message: msg})
    end

    ### methods to create error objects

    def self.res_false(error_name=nil)
      obj = Response.new(res: false)
      obj.set_error(error_name, "")
      obj.data={}
      obj.http_status = 500
      obj
    end

    def self.res_data(data={})
      obj = Response.new
      obj.set_data(data)
      obj
    end


    def self.res_error(error_name, msg, msg_sys='', http_status=nil, _sysdata={})
      r = Response.new
      r.set_error(error_name, msg, msg_sys, http_status, _sysdata)
      r
    end

    def self.res_error_badinput(error_name, msg, msg_sys='', _sysdata={})
      res_error error_name, msg, msg_sys, 400, _sysdata
    end

    def self.res_error_forbidden(error_name, msg, msg_sys='', _sysdata={})
      error_name = 'forbidden' if error_name.empty?
      res_error error_name, msg, msg_sys, 403, _sysdata
    end

    def self.res_error_exception(msg, exception, status=500, _sysdata={})
      res_error 'exception', msg, "#{exception.message}, #{exception.backtrace.inspect}", status, _sysdata
    end


    ### sys data

    def add_sysdata(_sysdata)
      self.sysdata ||= {}
      self.sysdata.merge! _sysdata
    end


    def set_sysdata(_sysdata)
      self.sysdata = _sysdata
      self
    end


    ### events in sensu
    def to_sensu_event_message
      {
          type: error_name,
          message: error_msg,
          data: sysdata
      }
    end
  end
end
