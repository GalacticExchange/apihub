class PropertiesController < BaseController

  def show
    # input
    name = params['name'] || ''


    #
    res = Gexcore::OptionService.get_option(name)

    return_json(res)
  end

  # return list of hadoop types
  def hadoop_types_list

    rows = ClusterHadoopType.w_enabled.order('pos asc, id asc').all

    data = rows.map{|r| r.to_hash}

    return_json_data(data)
  end

end

