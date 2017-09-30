class LibraryApplicationsController < AccountBaseController

  layout "sidebar_view"
  before_action {@page_selected = "appstore"}
  before_action :set_app, only: [:update]


  def show
    check_current_cluster || return
    @app = LibraryApplication.get_by_name(params[:name])

    app_hash = @app.to_hash

    scr = @app.images.map do |u|
      {
        "id": u.id,
        "url": ApplicationController.helpers.picture_url_library_application_image(u, :large)
      }
    end

    cluster_app = @cluster.applications.w_not_deleted.where(library_application_id: @app.id).first
    cluster_app_uid = cluster_app.uid if cluster_app

    app_hash.merge!(imageUrl: ApplicationController.helpers.picture_url_library_application(@app, :medium))
    app_hash.merge!(desc: @app.description)
    app_hash.merge!(scr: scr)
    app_hash.merge!(clusterApplicationId: cluster_app_uid)

    res = Gexcore::Response.res_data({app: app_hash})

    respond_to do |format|
      format.html{ }
      format.json{ return_json(res) }
    end
  end

  def index
    check_current_cluster || return
    @items = LibraryApplication.w_enabled.order('pos asc').all


    development = params[:dev] || params[:development]
    @items = development ? @items.w_dev : @items.w_handpicked


    # add images
    if params[:includeImages] == 'true'
      res_h = @items.map{|r| r.to_hash.merge!(imageUrl: ApplicationController.helpers.picture_url_library_application(r, :medium))}
    else
      res_h = @items.map{|i| i.to_hash}
    end

    # find installed apps
    res_h.each do |i|
      cluster_app = @cluster.applications.w_not_deleted.where(library_application_id: i[:id]).first
      cluster_app_uid = cluster_app.uid if cluster_app
      i.merge!(clusterApplicationId: cluster_app_uid)
    end

    res = Gexcore::Response.res_data({apps: res_h})

    respond_to do |format|
      format.html{ }
      format.json{ return_json(res) }
    end
  end



  def install

    @app = LibraryApplication.get_by_name(params[:name])

    json = File.read('input.json')
    @input_json = JSON.parse(json)

  end

  def get_lib_app_info(lib_app)
    data = {
        application: lib_app.to_hash_with_images,
        metadata: lib_app.metadata_hash
    }
    Gexcore::Response.res_data(data)
  end


  private

  def set_app
    @app = LibraryApplication.get_by_id(params[:id])
  end

end
