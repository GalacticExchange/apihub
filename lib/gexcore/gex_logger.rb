module Gexcore
  class GexLogger

    # levels
    LEVEL_TRACE = 'trace'
    LEVEL_DEBUG = 'debug'
    LEVEL_INFO = 'info'
    LEVEL_WARNING = 'warning'
    LEVEL_ERROR = 'error'
    LEVEL_CRITICAL = 'critical'

    LEVEL_ALIASES = {"fatal"=>LEVEL_CRITICAL, 'warn'=>LEVEL_WARNING}

    LEVELS = { LEVEL_TRACE => 1, LEVEL_DEBUG => 2, LEVEL_INFO => 3, LEVEL_WARNING => 4, LEVEL_ERROR => 5, LEVEL_CRITICAL => 6}
    LEVELS_BY_ID = LEVELS.invert

    #
    LEVEL_DEBUG_FROM = LEVEL_INFO

    LEVEL_DEFAULT = LEVEL_DEBUG


    ### source
    SOURCE_USER_ACTION = 'user_action'
    SOURCE_SERVER= 'server'





    # log to file
    def self.logger_file
      @@logger_file ||= Logger.new("#{Rails.root}/log/gex_#{Rails.env}.log")
      #@@logger_file.level = Logger::DEBUG
    end


    #
    def self.log_to_system?(level)
      # 2016-dec - always NO, no log_system used
      return false

      level_number(level.to_s.downcase) >= level_number(LEVEL_DEBUG_FROM.to_s.downcase)
    end

    def self.level_base_name(level_name)
      res = level_name.to_s.downcase
      res = '' if res=='all'

      # aliases
      if LEVEL_ALIASES[res].present?
        res = LEVEL_ALIASES[res]
      end

      res
    end

    def self.level_number(level)
      res = LEVELS.fetch(level.to_s.downcase, nil)

      res = 0 if res.nil?

      res
    end



    #
    FIELDS_BASIC = [:team_id, :cluster_id, :node_id, :ip]


    ###
    def self.log(version, source_name, level, msg, type_name, data={})
      # add some data
      data[:ip] ||= Gexcore::Settings.ip

      #
      if Gexcore::Settings.log_async.to_i==1
        LogWorker.perform_async(version, source_name, level, msg, type_name, data)
      else
        Gexcore::GexLogger.log_now(version, source_name, level, msg, type_name, data)
      end
    end





    ## main method to add log row

    def self.log_now(version, source_name, level, msg, type_name, data={})
      begin
        row_hash = build_log_hash(version, source_name, level, msg, type_name, data)

        if row_hash
          row_hash.delete('need_notify')
          row_hash.delete(:need_notify)

          level_id = row_hash[:level] || row_hash['level']

          # add to DB
          if Gexcore::Settings.log_to_db.to_i==1
            begin
              Timeout.timeout 2 do
                row_hash.delete(:type_name)
                row_hash.delete(:instanceID)
                row_hash.delete(:nodeID)
                row_hash.delete(:clusterID)

                row_debug = LogDebug.new(row_hash)
                row_debug.save!
              end
            rescue => e
              logger_file.fatal "cannot save log to DB. Exception: #{e.inspect}, backtrace: #{e.backtrace}"
            end

          end

          # slack
          if Gexcore::Settings.log_to_slack.to_i==1
            begin
              Timeout.timeout 2 do
                if level_id >= level_number(LEVEL_ERROR.to_s.downcase)
                  Gexcore::Log::Slack.error_to_slack(row_hash)
                end
              end
            rescue => e
              logger_file.fatal "cannot save log to slack. Exception: #{e.inspect}, backtrace: #{e.backtrace}"
            end

          end



          # add to log_system
          #if level_id.present? && log_to_system?(LEVELS_BY_ID[level_id])
          #  row = LogSystem.new(row_hash)
          #  row.save!
          #end

          # add to Kafka
          if Gexcore::Settings.log_to_kafka.to_i==1
            begin
              Timeout.timeout 2 do
                kafka = Kafka.new(seed_brokers: ["#{Gexcore::Settings.log_kafka_server_url}"])
                kafka.deliver_message("#{row_hash.to_json}", topic: Gexcore::Settings.log_kafka_topic)
                kafka.close
              end
            rescue => e
              logger_file.fatal "cannot save log to Kafka. Exception: #{e.inspect}, backtrace: #{e.backtrace}"
            end
          end

        end
      rescue => e
        logger_file.fatal "cannot save to log. Exception: #{e.inspect}, backtrace: #{e.backtrace}"
      end

      # add to Rabbit
=begin
      if level_id.present? && log_to_system?(LEVELS_BY_ID[level_id])
        #logger_file.fatal "need_notify == : #{need_notify.inspect}"
        if need_notify
          Gexcore::SensuEventsService.send_message_from_hash row_hash
        end
      end
=end

    end


    def self.build_log_hash(version, source_name, level, msg, type_name, data={})
      row_hash = {}

      begin
        #
        data = data.symbolize_keys

        #
        level = level.to_s.downcase

        # source
        source_name = source_name.to_s.downcase
        source = LogSource.get_by_name_or_create source_name
        source_id = source.nil? ? 0 : source.id


        # type
        type_name = type_name.to_s.downcase

        type = nil
        #type = LogType.get_by_name_or_create type_name
        #type_id = 0
        #subtype_id = 0



        # visible_client
        visible_client = false

        #
        need_notify = false


        if type
          visible_client = type.visible_client
          need_notify = type.need_notify

          #
          type_id = type.id

          #if !type.parent_id.nil? && type.parent_id>0
          #  subtype = type
          #  type = type.parent

          #  type_id = type.id
          #  subtype_id = subtype.id
          #end
        end

        #if type_name=~/^system/
        #  logger_file.fatal("log: type_id=#{type_id}")
        #end


        # msg
        if msg.nil?
          msg = type.title
        end

        ## auto define

        # user
        user_id = data[:user_id]
        if user_id.present?
          user = User.find_by(id: data[:user_id])

          # set team from user
          data[:team_id] = user.team_id unless data[:team_id].present?
        end


        # set data from node_id
        node = nil
        node = Node.get_by_uid(data[:node_uid]) if data[:node_uid].present?
        node = Node.get_by_id(data[:node_id]) if data[:node_id].present?

        if node
          data[:node_id] = node.id

          # set cluster from node
          data[:cluster_id] = node.cluster_id unless data[:cluster_id].present?

        end

        # set data from instance_uid
        instance = nil
        instance = Instance.get_by_uid(data[:instance_id]) if data[:instance_id].present?

        instance_id = instance.nil? ? nil : instance.id
        data[:instance_id] = instance_id

        # set data from cluster_id
        if data[:cluster_id].present?
          cluster = Cluster.find_by(id: data[:cluster_id])

          if cluster
            # set team from cluster
            data[:team_id] = cluster.team_id unless data[:team_id].present?
          end

        end

        # team
        unless data[:team_id].present?
          # set team from user
          data[:team_id] = user.team_id if user.present?
        end




        # level
        level_id = (level.is_a? String) ? LEVELS[level] : level

        # add to DB
        row_hash = {
            level: level_id,
            message: msg,
            source_id: source_id,
            #type_id: type_id,
            type_name: type_name,
            user_id: user_id,
            visible_client: visible_client,
        }

        FIELDS_BASIC.each do |f|
          v = data[f] || data[f.to_s] || nil
          next if v.nil?

          row_hash[f] = v
        end

        # ip
        row_hash[:ip] ||= Gexcore::Settings.ip

        # need_notify
        row_hash[:need_notify] = need_notify

        #
        row_hash[:instance_id] = instance_id
        #
        row_hash[:nodeID] = node.nil? ? (nil || data[:nodeID]) : node.uid
        #
        row_hash[:clusterID] = cluster.nil? ? (nil || data[:clusterID]) : cluster.uid
        #
        row_hash[:instanceID] = instance.nil? ? (nil || data[:instanceID]) : instance.uid

        #
        data ||={}
        data[:version] = version
        data[:type_name] = type_name
        data[:type_name] = type.name unless type.nil?

        #
        row_hash[:data] = data.to_json

        # date
        row_hash[:created_at] = Time.now.utc


      rescue => e
        logger_file.fatal "cannot build row log. Exception: #{e.inspect}, backtrace: #{e.backtrace}"
      end


      row_hash
    end


    def self.log_old(version, source_name, level, msg, type_name, data={})
      begin
        level = level.to_s.downcase

        # source
        source_name = source_name.to_s.downcase
        source = LogSource.get_by_name_or_create source_name
        source_id = source.nil? ? 0 : source.id


        # type
        type_name = type_name.to_s.downcase

        type = LogType.get_by_name_or_create type_name
        type_id = 0
        subtype_id = 0



        # visible_client
        visible_client = false

        #
        need_notify = false


        if type
          visible_client = type.visible_client
          need_notify = type.need_notify

          #
          type_id = type.id

          #if !type.parent_id.nil? && type.parent_id>0
          #  subtype = type
          #  type = type.parent

          #  type_id = type.id
          #  subtype_id = subtype.id
          #end
        end

        #if type_name=~/^system/
        #  logger_file.fatal("log: type_id=#{type_id}")
        #end


        # msg
        if msg.nil?
          msg = type.title
        end

        ## auto define

        # user
        user_id = data[:user_id]
        if user_id.present?
          user = User.find_by(id: data[:user_id])

          # set team from user
          data[:team_id] = user.team_id unless data[:team_id].present?
        end


        # set data from node_id
        node = nil
        node = Node.get_by_uid(data[:node_uid]) if data[:node_uid].present?
        node = Node.get_by_id(data[:node_id]) if data[:node_id].present?

        if node
          data[:node_id] = node.id

          # set cluster from node
          data[:cluster_id] = node.cluster_id unless data[:cluster_id].present?
        end

        # set data from instance_uid
        instance = nil
        instance = Instance.get_by_uid(data[:instance_id]) if data[:instance_id].present?

        instance_id = instance.nil? ? nil : instance.id
        data[:instance_id] = instance_id


        # set data from cluster_id
        if data[:cluster_id].present?
          cluster = Cluster.find_by(id: data[:cluster_id])

          if cluster
            # set team from cluster
            data[:team_id] = cluster.team_id unless data[:team_id].present?
          end

        end

        # team
        unless data[:team_id].present?
          # set team from user
          data[:team_id] = user.team_id if user.present?
        end




        # level
        level_id = (level.is_a? String) ? LEVELS[level] : level

        # add to DB
        row_hash = {
            level: level_id,
            message: msg,
            source_id: source_id,
            type_id: type_id,
            type_name: type_name,
            user_id: user_id,
            visible_client: visible_client,
            }

        FIELDS_BASIC.each do |f|
          v = data[f] || data[f.to_s] || nil
          next if v.nil?

          row_hash[f] = v
        end

        # ip
        row_hash[:ip] ||= Gexcore::Settings.ip

        # need_notify
        row_hash[:need_notify] = need_notify

        #
        row_hash[:instance_id] = instance_id

        #
        data ||={}
        data[:version] = version
        data[:type_name] = ''
        data[:type_name] = type.name unless type.nil?
        row_hash[:data] = data.to_json

        # date
        row_hash[:created_at] = Time.now.utc


        # add to DB
        #log_row_hash(row_hash)
        log_row_hash_async(row_hash)

      rescue => e
        logger_file.fatal "cannot save to log. Exception: #{e.inspect}, backtrace: #{e.backtrace}"
      end
    end



    def self.version
      Gexcore::Settings.get_option_api_version
    end

    def self.debug_msg(msg, data={})
      log(version, LEVEL_DEBUG, msg, 'debug', data)
    end

    def self.trace(type_name, msg, data={})
      log(version, SOURCE_SERVER, LEVEL_TRACE, msg, type_name || 'trace', data)
    end

    def self.debug(type_name, msg, data={})
      log(version, SOURCE_SERVER, LEVEL_DEBUG, msg, type_name || 'error_general', data)
    end

    def self.debug_exception(type_name, msg, e, data={})
      data[:exception] = {message: e.message, backtrace: e.backtrace.inspect}
      lvl = LEVEL_DEBUG
      log(version, SOURCE_SERVER, lvl, msg, type_name, data)
    end

    def self.info(type_name, msg, data={})
      log(version, SOURCE_SERVER, LEVEL_INFO, msg, type_name || 'info_general', data)
    end


    def self.warning(type_name, msg, data={})
      log(version, SOURCE_SERVER, LEVEL_WARNING, msg, type_name || 'error_general', data)
    end

    def self.error(type_name, msg, data={})
      log(version, SOURCE_SERVER, LEVEL_ERROR, msg, type_name || 'error_general', data)
    end

    def self.critical(type_name, msg, data={})
      log(version, SOURCE_SERVER, LEVEL_CRITICAL, msg, type_name || 'error_general', data)
    end


    def self.exception(msg, e, data={}, lvl=nil)
      data[:exception] = {message: e.message, backtrace: e.backtrace.inspect}
      lvl ||= LEVEL_CRITICAL
      log(version, SOURCE_SERVER, lvl, msg, 'exception', data)
    end


    def self.debug_response(res, msg, extra_data={})
      data = res.data.merge(res.sysdata).merge(extra_data)
      if data[:res].nil?
        data[:res] = res.success?
      end

      debug('debug', msg, data)
    end

    def self.log_response_base(res, level, extra_data={})
      data = res.data.merge(res.sysdata).merge(extra_data)
      if data[:res].nil?
        data[:res] = res.success?
      end

      send(level.to_sym, res.error_name, res.error_msg_human, data)
    end


    def self.log_response(res, type_success, success_msg, type_error, extra_data={})
      #
      data = res.data.merge(res.sysdata).merge(extra_data)

      if res.success?
        msg = process_msg_string success_msg, data

        info(type_success, msg, data)
      else
        error(type_error, res.error_msg_human, data)
      end

    end

    ### helper methods
    def self.process_msg_string(msg, data)

      msg.gsub(/\:([a-z_]+)/) do |s|
        f = Regexp.last_match[1].to_s
        data[:"#{f}"] || ''
      end
    end
  end




=begin
  class LoggerUserAction
    def self.add(log_name, data={})
      log_type = LogUserActionType.get_by_name(log_name)
      r = LogUserAction.new(log_user_action_type_id: log_type.id, user_id: user_id, data: data)
      r.save
    end
  end
=end

end

