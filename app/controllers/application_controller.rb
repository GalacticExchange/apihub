class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  skip_before_action :verify_authenticity_token, if: :json_request?

  ### logger
  def gex_logger
    Gexcore::GexLogger
  end




  ## error handling
  unless Rails.application.config.consider_all_requests_local
  #if 1==1
  #if 0==1
    rescue_from Exception, with: lambda { |exception| render_error 500, exception }
    rescue_from ActionController::RoutingError, ActionController::UnknownController, ::AbstractController::ActionNotFound, ActiveRecord::RecordNotFound, with: lambda { |exception| render_error 404, exception }
  end

  ### error handling

  def raise_not_found!
    raise ActionController::RoutingError.new("Page not found: #{params[:unmatched_route]}")
  end


  def render_error(status, exception)
    #$Mylog.log_event 'error', 'exception', "#{status}, url: #{request.original_url}, referer: #{request.env["HTTP_REFERER"]}, ip: #{request.env["REMOTE_ADDR"]}, #{request.env["HTTP_X_FORWARDED_FOR"]}, #{exception.inspect}, #{(exception.backtrace || []).join('\n').truncate(8000)}"
    #gex_logger.fatal "exception, #{status}, url: #{request.original_url}, referer: #{request.env["HTTP_REFERER"]}, ip: #{request.env["REMOTE_ADDR"]}, #{request.env["HTTP_X_FORWARDED_FOR"]}, #{exception.inspect}, #{(exception.backtrace || []).join('\n').truncate(8000)}"

    #
    msg = status==404 ? 'Resource not found' : 'Unexpected error occurred'

    if exception.is_a?(Gexcore::Response)
      @res = exception
      gex_logger.error 'error', @res.error_msg_human
    else
      @res = Gexcore::Response.res_error_exception(msg, exception, status, {request: request_hash_log})

      if status==404
        gex_logger.info 'page_not_found', 'page not found', {request: request_hash_log}
      else
        gex_logger.exception 'exception', exception
      end

    end


    #
    if ['development'].include? Rails.env
      #raise exception
    end

    #
    respond_to do |format|
      format.html {
        render template: "errors/error_#{status}", status: status
      }
      format.json {
        render :json => @res.get_error_data, :status => @res.http_status
      }
    end
  end



  ### helpers

  def json_request?
    request.format.json?
  end




  ### logging

  def log_request_start
    #ip = request.remote_ip
    client_version = request.headers['clientVersion']

    msg = ("request #{request.request_method} #{request.path}") rescue ""
    gex_logger.trace "api_request_start", msg, {
        #ip: ip,
        request: request_hash_log,
        client_version: client_version
    }

  end

  def request_hash_log
    h = {}
    #return {}

    h[:path] = request.path
    h[:method] = request.request_method

    #
    p = params.reject{|k| ['password'].include? k}
    p.each do |k,v|
      h[k] = v
    end



    # headers
    h['headers'] = {}

    #request.headers.each do |key, value|
      #h['headers'][key] = value
      #if key.downcase.starts_with?('http')
    #end

    return h
  rescue => e
    return {res: 0, error: e.message}
  end





end
