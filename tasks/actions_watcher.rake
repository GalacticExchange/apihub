namespace :subscribe do
  task :redis => :environment do

    notify_channel = "#{Gexcore::Settings.redis_prefix}:#{Gexcore::Settings.provision_env}:#{Gexcore::Settings.provisioner_notify_channel}"

    $redis.subscribe(notify_channel) do |on|
      on.message do |channel, message|

        msg = JSON.parse(message) rescue nil

        if msg.nil?
          Gexcore::GexLogger.error('debug_provision', 'cannot parse message', {message: message})
          next
        end

        action_type = msg['type']
        action_info = msg['info']

        if action_type.nil? || action_info.nil?
          Gexcore::GexLogger.error('debug_provision', 'wrong message format', {message: message})
          next
        end

        item_name, item_id = action_info.first rescue nil

        Gexcore::GexLogger.info('debug_provision', "received message - #{action_type}", {action: action_type, "#{item_name}": item_id})
        res = Gexcore::NotificationService.notify(action_type.to_sym, action_info)

        if res.error?
          Gexcore::GexLogger.error('debug_provision', 'notify failed', {message: message, res: res, "#{item_name}": item_id})
        else
          Gexcore::GexLogger.info('debug_provision', 'notify finished', {message: message, "#{item_name}": item_id})
        end

        # debug
        # p Time.now, res, msg

      end
    end
  end

  # debug
  task :publisher do
    notify_channel = "#{Gexcore::Settings.redis_prefix}:#{Gexcore::Settings.provision_env}:#{Gexcore::Settings.provisioner_notify_channel}"
    $redis.publish notify_channel, {type: 'cluster_provision_uninstall_error', info: {cluster_id: 679}}.to_json
  end

end