class Admin::ClusterApplicationsController < Admin::MyAdminBaseController

  autocomplete :cluster_application, :name, :full => true

  def model
    ClusterApplication
  end

# search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_cluster_applications_url, search_url: :search_admin_cluster_applications_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :cluster, :string, :autocomplete, {label: 'Cluster', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_cluster_name_admin_clusters_path, input_html: {style: "width: 180px"}}
    field :library_application, :string, :autocomplete, {label: 'Library application', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_library_application_name_admin_library_applications_path, input_html: {style: "width: 180px"}}
    field :uid, :string, :text, {label: 'UID', default_value: '', condition: :like_full, input_html: {style: "width: 200px"}}

  end

  def index
    @cluster_id = params[:cluster_id]
    @library_application_id = params[:library_application_id]

    if @cluster_id
      @cluster = Cluster.find(@cluster_id)
      @filter.set 'cluster_id', @cluster_id
      @filter.set 'cluster', @cluster.name

    end

    if @library_application_id
      @library_application = LibraryApplication.find(@library_application_id)
      @filter.set 'library_application_id', @library_application_id
      @filter.set 'library_application', @library_application.name

    end

    @items = ClusterApplication.includes(:library_application, :cluster => [:team]).by_filter(@filter)

    ids = @items.map(&:id)

    # counts
    @count_services = ClusterService.where(:application_id => ids).group(:application_id).count
  end

  def show
    application_id = params[:id]

    if application_id.nil?
      raise 'Bad input'
    end

    #
    @item = model.find(application_id)

    @containers = @item.containers

    # config
    @config_filename = (Gexcore::Applications::Service.config_for_application_filename(@containers.first, @item) rescue nil)
    @config_content = (File.read(@config_filename) rescue 'ERROR')

    #
    @cluster = @item.cluster
    @user = @cluster.primary_admin

    @user_token = Gexcore::AuthService.get_new_token @user

    # consul info
    @info_consul = Gexcore::Consul::Service.get_app_data(@item)
    @info_consul_settings = Gexcore::Consul::Service.get_app_settings(@item)

  end



  def send_command

    @item = model.find(params[:id])
    @cmd = params[:cmd]

    if @cmd=='uninstall'
      @res = Gexcore::Applications::Service.uninstall_application(nil, @item)
    elsif @cmd=='remove'
      @res = Gexcore::Applications::Service.remove_application(@item)
    else
      @res = Gexcore::Response.res_error('admin_error', 'Bad command')
    end


    respond_to do |format|
      format.html {      }
      format.json{ render :json=>@res }

    end
  end


end
