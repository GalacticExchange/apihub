class KeysController < AccountBaseController

  def model
    current_user.keys
  end


  # keys list for user
  def index
    items = model.all.order("id desc") #.pluck
    items_hash = items.map{|i| i.to_hash_secure}

    return_json(Gexcore::Response.res_data({keys: items_hash} ))
  end



  def create

    type = params[:type]
    res = Gexcore::Response.new
    types = Key::KEY_TYPES

    creds = params[:creds]
    name = params[:name]


    if type.nil? || !types.keys.include?(type.to_sym)
      return return_json(res.set_error_badinput('bad_request', "Bad request", "No type specified/Wrong type provided"))
    end

    if creds.nil?
      return return_json(res.set_error_badinput('bad_request', "Bad request", "Empty credentials"))
    end

    res = Gexcore::Keys::Service.add_key(res, current_user, type, creds, name)


    return_json(res)
  end


  def remove

    key_id = params[:id]

    if key_id.nil? || key_id == ''
      return return_json(res.set_error_badinput('bad_request', "Bad request", "Provide key id"))
    end

    res = Gexcore::Keys::Service.remove_key_by_user(current_user, key_id)

    return_json(res)
  end


end
