# tmp here
class Hash
  def to_hash_recursive
    result = self.to_hash

    result.each do |key, value|
      case value
        when Hash
          result[key] = value.to_hash_recursive
        when Array
          result[key] = value.to_hash_recursive
        when ActionController::Parameters
          result[key] = value.to_hash_recursive
      end
    end

    result
  end
end



class ClusterApplicationsController < AccountBaseController
  layout "sidebar_view"

  before_action { @page_selected = "apps" }


  #search_filter :index, {url: :cluster_applications_path} do
  #  default_order "id", 'asc'
  #  field :name, :string, :text, {label: 'Name', default_value: '', condition: :like_full}
  #end


  def model
    ClusterApplication
  end

  def model_name
    :cluster_application
  end

  def apps_model
    @current_cluster.applications.w_not_deleted
  end


  def create_gex_app
    params_app = params[:cluster_application]
    params_app = params if params_app.nil? || params_app.empty?

    node_uid = params_app[:nodeID] || params_app[:node_uid]

    p_settings = params_app[:settings]
    appname = params_app[:applicationName] || params_app[:application_name]

    lib_app = LibraryApplication.get_by_name(appname)

    if lib_app.nil?
      @res = Gexcore::Response.res_error_badinput("application_not_found", "Application not found", "app #{appname} not found")
      return return_json(@res)
    end

    if p_settings.is_a?(String)
      p_settings = (JSON.parse(p_settings) rescue {})
    end
    settings = p_settings.to_hash_recursive.deep_symbolize_keys

    @res = Gexcore::Applications::Service.install_application_by_user_new(current_user, lib_app.name, node_uid, settings, 'gex')
    gex_logger.log_response(@res, 'application_create', "Application has been added to the cluster", 'application_create_error')

    if @res.success?
      app = ClusterApplication.get_by_id(@res.data[:application_id])
      return_json_data(app.to_hash_created)
    else
      return_json(@res)
    end
  end


  def create_new
    # input
    params_app = params[:cluster_application]
    params_app = params if params_app.nil? || params_app.empty?

    node_uid = params_app[:nodeID] || params_app[:node_uid]
    appname = params_app[:applicationName] || params_app[:application_name]
    app_type = params_app[:applicationType] || params_app[:application_type] || 'gex'
    p_settings = params_app[:settings]

    lib_app_id = params[:library_application_id]


    # check lib/apphub app by id/name
    if params_app[:external]
      lib_app = Gexcore::Apphub::Service.get_by_id(lib_app_id)
      name_or_id = lib_app_id
    else
      lib_app = appname.nil? ? LibraryApplication.get_by_id(lib_app_id) : LibraryApplication.get_by_name(appname)
      name_or_id = lib_app.name unless lib_app.nil?
    end

    if lib_app.nil? || name_or_id.nil?
      @res = Gexcore::Response.res_error_badinput("application_not_found", "Application not found", "app #{appname} not found")
      return return_json(@res)
    end

    if p_settings.is_a?(String)
      p_settings = (JSON.parse(p_settings) rescue {})
    end

    external = params_app[:external]? params_app[:external] : false

    # create app
    settings = p_settings.to_hash_recursive.deep_symbolize_keys
    @res = Gexcore::Applications::Service.install_application_by_user(current_user, name_or_id, node_uid, settings, external, app_type)


    # log
    gex_logger.log_response(@res, 'application_create', "Application has been added to the cluster", 'application_create_error')

    # return res
    respond_to do |format|
      format.html {
        #todo: unused
        if @res.success?
          app = ClusterApplication.get_by_id(@res.data[:application_id])
          redirect_to NgRoutes::APPLICATIONS_INFO.gsub('{cluster_id}', @current_cluster.uid).sub('{application_id}', app.uid)
        else
          redirect_to install_config_application_path(:cluster_id => @current_cluster.id, :name => appname), :flash => {:error => @res.error_desc}
        end
      }
      format.json {
        if @res.success?
          app = ClusterApplication.get_by_id(@res.data[:application_id])
          return_json_data(app.to_hash_created)
        else
          return_json(@res)
        end
      }
    end

  end

  # todo: deprecated
  def create
    # input
    params_app = params[:cluster_application]
    params_app = params if params_app.nil? || params_app.empty?


    node_uid = params_app[:nodeID] || params_app[:node_uid]
    appname = params_app[:applicationName] || params_app[:application_name]
    p_settings = params_app[:settings]

    #
    if !appname.nil?
      library_app = LibraryApplication.get_by_name(appname)
    else
      library_app = LibraryApplication.get_by_id(params[:library_application_id])
    end


    if library_app.nil? && !params_app[:external]
      @res = Gexcore::Response.res_error_badinput("application_not_found", "Application not found", "app #{appname} not found")
      return return_json(@res)
    end

    #
    @item = ClusterApplication.new
    @item.cluster = @current_cluster
    @item.node_uid = node_uid


    @item.library_application_id = params_app[:external] ? params_app[:id] : library_app.id
    @item.external = params_app[:external]


    # settings
    #gex_logger.debug("debug", "install app", {settings: p_settings})

    if p_settings.is_a?(String)
      p_settings = (JSON.parse(p_settings) rescue {})
    end
    @item.settings = p_settings


    # debug
    #settings = nil

    # create app
    @res = Gexcore::Applications::Service.install_application_by_user(current_user, appname, node_uid, @item.settings, @item.library_application_id)


    # log
    gex_logger.log_response(@res, 'application_create', "Application has been added to the cluster", 'application_create_error')

    # return res
    respond_to do |format|
      format.html {
        if @res.success?
          app = ClusterApplication.get_by_id(@res.data[:application_id])
          redirect_to NgRoutes::APPLICATIONS_INFO.gsub('{cluster_id}', @current_cluster.uid).sub('{application_id}', app.uid)
        else
          redirect_to install_config_application_path(:cluster_id => @current_cluster.id, :name => appname), :flash => {:error => @res.error_desc}
        end
      }
      format.json {
        if @res.success?
          app = ClusterApplication.get_by_id(@res.data[:application_id])
          return_json_data(app.to_hash_created)
        else
          return_json(@res)
        end
      }
    end

  end


  def show
    init_cluster || (return return_json(Gexcore::Response.new.set_error_badinput('', 'wrong cluster id provided', "wrong cluster id provided")) )
    @app = apps_model.get_by_uid(params[:uid])
    res = Gexcore::Response.new
    type = params[:type] || ''
    method_name = "to_hash#{type}".to_sym

    # check app status
    if @app.nil? || @app.removed?
      return return_json(res.set_error('app_uninstall_not_found', 'Application is removed', 'try to get removed app', 404))
    end


    if !@app.nil? && @app.respond_to?(method_name)
      res.set_data({ application: @app.send(method_name) })
    else
      res.set_error_badinput("", "wrong type", "wrong type")
    end

    respond_to do |format|
      format.html {  }
      format.json { return_json(res) }
    end
  end


  def index
    init_cluster || (return return_json(Gexcore::Response.new.set_error_badinput('', 'wrong cluster id provided', "wrong cluster id provided")) )
    @items = apps_model.w_user_apps.includes(:library_application).order('id desc').limit(1000)
    res = Gexcore::Response.new
    type = params[:type] || ''
    method_name = "to_hash#{type}".to_sym

    if !@items.empty?
      if @items[0].respond_to?(method_name)
        resp_arr = @items.map(&method_name)
        res.set_data({apps: resp_arr})
      else
        res.set_error_badinput("", "wrong type", "wrong type")
      end
    else
      res.set_data({results: nil})
    end

    respond_to do |format|
      format.html {  }
      format.json { return_json(res) }
    end
  end

  #todo: refactor (api-only method)
  def panel
    init_cluster || (return return_json(Gexcore::Response.new.set_error_badinput('', 'wrong cluster id provided', "wrong cluster id provided")) )
    @app = apps_model.get_by_uid(params[:uid])
    if @app.nil?
      raise_not_found
    end
    @library_app = @app.library_application

    @containers = @app.containers.w_not_deleted.order('id desc').limit(1000)
    @services = @app.services.w_not_deleted.order('id desc').limit(1000)


    @page_selected="app_#{@app.name}"
  end

  def edit
    @app = apps_model.find_by_name(params[:name])
  end


  def install_config_external

    check_current_cluster || return

    cred = {
        github_user: params[:github_user],
        url_path: params[:url_path]
    }

    #app_metadata = Gexcore::Applications::Service.app_meta(cred, true)

    app_metadata = Gexcore::Applications::Metadata.new('')
    app_metadata.initialize_new(cred, true)
    app_metadata.load


    @all_nodes = @current_cluster.nodes.w_joined.order('id desc').all
    @all_nodes = @all_nodes.map { |node| node.to_hash }

    r = Gexcore::Response.res_data(
   {
          nodes: @all_nodes,
          attributes: app_metadata.get_attributes,
          services: app_metadata.get_services
        }
    )

    return_json(r)
  end



  def check_requirements

    lib_app_name = params[:lib_app_name]
    node_uid = params[:nodeID] || params[:node_uid]

    res = Gexcore::Applications::InstallChecks.check_requirements_by_user(lib_app_name, node_uid, current_user)

    return_json(res)
  end


  def install_config

    check_current_cluster || return

    @app_library = LibraryApplication.get_by_name(params[:name])

    #
    @app_name = @app_library.name

    @item = ClusterApplication.new
    @item.library_application = @app_library
    @item.application_name = @app_library.name
    @item.cluster = @current_cluster

    # node - default
    @node = @current_cluster.nodes.w_joined.first
    if @node
      @item.node_uid = @node.uid
      #@item.settings = @item.default_settings
      #@item.set_default_settings

      @env = Gexcore::Applications::ConfigService.build_env(@app, current_user, @current_cluster, @node)

      #@config = Gexcore::Applications::Service.build_install_config(@item, @env)
      # app settings
      @app_metadata = Gexcore::Applications::Metadata.new(@app_name)
      @app_metadata.load

      @app_info = @app_metadata.get_app_info

      #
      @config = Gexcore::Applications::InstallConfig.new(@app_name)

      # from metadata
      @config.init_from_metadata_old(@app_metadata)

      # init values from env
      @config.build_properties(@env)


      #
      @item.settings = @config.properties
      @fields_metadata = @config.props_metadata

      @item.settings.each do |i|
        @fields_metadata[i[0]][:default_value] = i[1]
      end

      props_metadata = @app_metadata.get_config_params
      @fields_metadata.each do |i|
        p = props_metadata[i[0]]
        i[1][:visible] = p[:visible].nil? ? 1 : 0
      end

      @tree_metadata = Gexcore::Applications::InstallConfig.build_tree_from_plain(@fields_metadata)

    end


    #
    @all_nodes = @current_cluster.nodes.w_joined.order('id desc').all
    @all_nodes = @all_nodes.map { |node| node.to_hash }

    @res = Gexcore::Response.res_data(
        {
            nodes: @all_nodes,
            libApp: @app_library.to_hash_with_images,
            metadata: @tree_metadata,
            app_info: @app_info
    }
    )

    #
    respond_to do |format|
      format.html {}
      format.json { return_json(@res) }
    end

  end


  # uninstall app

  def uninstall
    @app_uid = get_app_uid
    #@app = (ClusterApplication.get_by_uid(@app_uid) rescue nil)

    @res = Gexcore::Applications::Service.uninstall_application_by_user(current_user, @app_uid)

    respond_to do |format|
      format.html { redirect_to cluster_applications_path(:cluster_uid => @current_cluster.uid) }
      format.json { return_json(@res) }
    end
  end


  # remove app
  def destroy
    # input
    app_uid = get_app_uid

    # work
    res = Gexcore::Applications::Service.remove_application_by_user(current_user, app_uid)

    # log
    gex_logger.log_response(res, 'app_removed', "Application was removed", 'app_remove_error')

    #

    respond_to do |format|
      format.html { redirect_to cluster_applications_path(:cluster_uid => @current_cluster.uid) }
      format.json { return_json(res) }
    end
  end


  ###

  def edit_comments
    @app = apps_model.find(params[:id])
    @library_app = LibraryApplication.find(@app.library_application_id)
  end


  def update_comments

    init_cluster || (return return_json(Gexcore::Response.new.set_error_badinput('', 'wrong cluster id provided', "wrong cluster id provided")) )

    @item = apps_model.find_by_uid(params[:id])
    @res = @item.update_attributes(item_comments_params)

    respond_to do |format|
      format.html {
        if @res
          redirect_to cluster_application_edit_path(cluster_uid: @current_cluster.uid, :name => @item.name, :uid => @item.uid), notice: "Application updated"
        else
          redirect_to cluster_application_edit_path(cluster_uid: @current_cluster.uid, :name => @item.name, :uid => @item.uid), notice: "Something went wrong"
        end
      }
      format.json { return_json_data(@res) }
    end
  end


  private

  def get_app_uid
    get_param_value(:applicationID) || get_param_value(:id) || get_param_value(:uid) || ''
  end


  def item_comments_params
    params.require(model_name).permit(:title, :notes)
  end


end
