class ApphubController  < AccountBaseController

  # with search
  def index

    appname = params[:appname] || ''
    page = params[:page] || '1'
    per_page = params[:itemsPerPage] || params[:perPage] || params[:per_page] || ''

    #items = Gexcore::Apphub::Service.search_list(appname, page,per_page, [:container,:compose_application])
    items = Gexcore::Apphub::Service.search_list(appname, page,per_page, [:container])
    res = Gexcore::Response.res_data({apps: items['store_applications'], total: items['total']})

    return_json(res)
  end

  def show

    init_cluster || (return return_json(Gexcore::Response.new.set_error_badinput('', 'wrong cluster id provided', "wrong cluster id provided")) )

    app_id = params[:id] || params[:appId]  ||  params[:appID] || ''
    res = Gexcore::Apphub::Service.get_by_id(app_id)

    @all_nodes = @current_cluster.nodes.w_joined.order('id desc').all
    @all_nodes = @all_nodes.map { |node| node.to_hash }

    r = Gexcore::Response.res_data(
        {
            nodes: @all_nodes,
            app: res
        }
    )


    return_json(r)
  end


  def get_app_id
    @app_id = params[:id] || params[:appId]  ||  params[:appID] || ''
  end


end
