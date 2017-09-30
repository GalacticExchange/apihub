module Gexcore
  class MessagesService < BaseService

    def self.get_dialog_by_users(user1_id, user2_id)
      MessageDialog.get_by_users user1_id, user2_id
    end

    ###
    def self.add_message(from_user_id, to_user_id, msg)
      res = Response.new

      begin

        # find dialog
        dialog = MessageDialog.find_or_create_by_users(from_user_id, to_user_id)

        #
        row = Message.new(from_user_id: from_user_id, to_user_id: to_user_id, dialog_id: dialog.id, message: msg)
        row.save!

        res.sysdata[:message_id] = row.id

        #
        after_message_added(row)
      rescue => ex
        return res.set_error_exception('cannot add message', ex)
      end

      res.set_data
    end


    def self.get_messages(user_id, filter_params)
      to_username = filter_params.fetch(:username, nil)

      rows = []

      unless to_username.nil?
        to_user = User.get_by_username to_username
        unless to_user.nil?
          dialog = get_dialog_by_users(user_id, to_user.id)
          unless dialog.nil?
            rows = get_messages_in_dialog user_id, dialog.id, filter_params
          end
        end
      else
        rows = get_messages_for_user user_id, filter_params
      end

      # pack and return
      data = rows.map{|r| r.to_hash}
      Response.res_data({messages: data})
    end

    def self.get_messages_in_dialog(user_id, dialog_id, filter_params={})
      filter_params[:dialog_id] = dialog_id

      rows = Message.get_list(filter_params)

      # update counters
      update_counters_after_read_messages_in_dialog(user_id, dialog_id)

      #
      rows
    end

    def self.get_messages_for_user(user_id, filter_params={})
      filter_params[:user_id] = user_id
      rows = Message.get_list(filter_params)

      #
      update_counters_after_read_messages_all(user_id)

      #
      rows
    end


    def self.update_counters_after_read_messages_in_dialog(user_id, dialog_id)
      # unread msg in the dialog
      key = redis_key_dialog_unread_count(user_id)
      $redis.hset(key, dialog_id.to_s, 0)

      # unread msg for user
      n_all = 0
      a = $redis.hvals(key)
      #a.inject{|n_all,x| n_all + x.to_i }
      a.each do |v|
        x  =v.to_i
        n_all = n_all+v.to_i
      end
      $redis.set(redis_key_unread_count(user_id), n_all)

    end


    def self.update_counters_after_read_messages_all(user_id)
      #
      $redis.set(redis_key_unread_count(user_id), 0)

      # unread msg in all dialogs
      key_dialogs = redis_key_dialog_unread_count(user_id)
      fields = $redis.hkeys(key_dialogs)
      fields.each do |f_dialog|
        $redis.hdel key_dialogs, f_dialog
      end

    end

    ## counters

    def self.get_unread_count_user(user_id)
      key = redis_key_unread_count user_id
      v = $redis.get(key)
      v = 0 if v.nil?
      v.to_i
    end


    def self.get_unread_count_in_dialog(user_id, dialog_id)
      key = redis_key_dialog_unread_count user_id
      t = $redis.type(key)
      v = $redis.hget(key, dialog_id.to_s)
      v = 0 if v.nil?
      v.to_i
    end



    ### dialogs

    def self.get_dialogs_for_user(user_id)
      dialogs = list_dialogs_for_user user_id

      #
      data = []
      dialogs.each do |r|
        hash = r.to_hash(user_id)
        hash[:unreadCount] = get_unread_count_in_dialog(user_id, r.id)

        data << hash
      end

      #
      return Response.res_data({dialogs: data})
    end


    def self.list_dialogs_for_user(user_id)
      MessageDialog.includes(:from_user, :to_user).where("from_user_id=? OR to_user_id=?", user_id, user_id).order('updated_at DESC').limit(100)
    end


    def self.get_dialog_info_for_user(user, to_user)
      return Response.res_error_badinput('dialog_info_badinput', 'Wrong username', 'Bad user ') if to_user.nil?

      #
      dialog = get_dialog_by_users(user.id, to_user.id)
      #return Response.res_error_badinput('dialog_info_notfound', 'No messages', 'Dialog not found') if dialog.nil?

      if dialog.nil?
        hash = MessageDialog.to_hash_no_dialog(user.id, to_user)
        hash[:unreadCount] = 0

        #
        return Response.res_data({dialog: hash})
      end

      #
      r = dialog
      hash = r.to_hash(user.id)
      hash[:unreadCount] = get_unread_count_in_dialog(user.id, r.id)

      #
      return Response.res_data({dialog: hash})
    end


    ### unread


    def self.after_message_added(msg)

      # dialog update
      dialog = msg.message_dialog
      dialog.last_message_id = msg.id
      dialog.updated_at = Time.now.utc
      dialog.save


      to_user_id = msg.to_user_id
      # update unread count for the user
      key = redis_key_unread_count(to_user_id)
      $redis.incr key

      v = $redis.get key

      # update unread count for the dialog
      $redis.hincrby redis_key_dialog_unread_count(to_user_id), msg.dialog_id, 1

    end

    def self.set_all_messages_read(user_id)
      # update unread count
      key = redis_key_unread_count user_id
      $redis.del key

    end


    ### redis

    def self.redis_key_unread_count(user_id)
      config.redis_prefix+":messages:#{user_id}:unread_count"
    end

    def self.redis_key_dialog_unread_count(user_id)
      config.redis_prefix+":messages_dialogs:#{user_id}:unread_count"
    end

  end
end

