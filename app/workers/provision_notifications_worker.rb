class ProvisionNotificationsWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :provisionnotify, :retry => false

  def perform(args)

    Gexcore::GexLogger.info('debug_provision', 'notification from provisioner received', {message: args})

    event_name = args['event']
    data = args['data']

    if event_name.nil? || data.nil?
      Gexcore::GexLogger.error('debug_provision', 'wrong message format', {message: data})
      return
    end

    item_name, item_id = data

    Gexcore::GexLogger.info('debug_provision', "received message - #{event_name}", {action: event_name, "#{item_name}": item_id})
    res = Gexcore::NotificationService.notify(event_name.to_sym, data)

    if res.error?
      Gexcore::GexLogger.error('debug_provision', 'notify failed', {args: args, res: res.get_error_data, "#{item_name}": item_id})
    else
      Gexcore::GexLogger.info('debug_provision', 'notify finished', {args: args, "#{item_name}": item_id})
    end

    # debug
    # p Time.now, res, msg

  end

end
