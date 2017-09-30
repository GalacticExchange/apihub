module Gexcore::Keys
  class Service < Gexcore::BaseService

=begin
    def self.add_key_for_user(user, type, creds)
      mtd = "add_#{type}_key".to_sym
      if !Gexcore::Keys::Service.respond_to?(mtd)
        #gex_logger.info "notify_cluster_error", "Bad event #{cluster_event_name}", {cluster_id: cluster_id, params: params}
        #return Response.res_error('notify_cluster_error', "Bad event #{cluster_event_name}")
      end
    end
=end

    def self.add_key(res, user, type, creds, name)
      res ||= Response.new

      key_type = type.to_sym

      if Key::KEY_TYPES[key_type].nil?
        # todo
        return nil
      end

      aws_creds = {}

      Key::KEY_TYPES[key_type].each do |f_name, f_info|
        aws_creds[f_name] = creds[f_name]
        if creds[f_name].nil? && f_info[:required]
          return Response.res_error('todo', "Bad credentials: #{creds}")
        end
      end

      key = Key.create(user: user, creds: aws_creds.to_json, key_type: key_type, name: name)

      if key
        res.set_data(key.to_hash_secure)
      end

      res
    end

    def self.remove_key_by_user(user, key_id)
      res = Response.new

      key = user.keys.where(id: key_id).first

      if key.nil?
        return return_json(res.set_error_badinput('bad_request', "Bad request", "Key not found for this user"))
      end

      result = key.destroy

      if !result
        return return_json(res.set_error_exception('Cannot remove key', ''))
      end

      res.set_data(1)
    end


  end
end