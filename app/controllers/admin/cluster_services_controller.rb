class Admin::ClusterServicesController < Admin::MyAdminBaseController

  # search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_cluster_services_url, search_url: :search_admin_cluster_services_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :status, :int, :select, {
        label: 'Status',
        default_value: -1, ignore_value: -1,
        collection: ClusterService.for_filter_statuses
    }

    field :cluster, :string, :autocomplete, {label: 'Cluster', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_cluster_name_admin_clusters_path, input_html: {style: "width: 180px"}}
    field :node, :string, :autocomplete, {label: 'Node', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_node_name_admin_nodes_path, input_html: {style: "width: 180px"}}
    field :application, :string, :autocomplete, {label: 'Application', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_cluster_application_name_admin_cluster_applications_path, input_html: {style: "width: 180px"}}
    field :container, :string, :autocomplete, {label: 'Container', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_cluster_container_name_admin_cluster_containers_path, input_html: {style: "width: 180px"}}

  end

  def index
    @cluster_id = params[:cluster_id]
    @node_id = params[:node_id]
    @application_id = params[:application_id]
    @container_id = params[:container_id]

    if @cluster_id
      @cluster = Cluster.find(@cluster_id)
      @filter.set 'cluster_id', @cluster_id
      @filter.set 'cluster', @cluster.name

    end

    if @node_id
      @node = Node.find(@node_id)
      @filter.set 'node_id', @node_id
      @filter.set 'node', @node.name

    end

    if @application_id
      @application = ClusterApplication.find(@application_id)
      @filter.set 'aplication_id', @application_id
      @filter.set 'application', @application.name
    end

    if @container_id
      @container = ClusterContainer.find(@container_id)
      @filter.set 'container_id', @container_id
      @filter.set 'container', @container.name
    end

    @items = ClusterService.includes(:node, :application, :cluster, :container, :library_service).by_filter(@filter)

  end

  def show
    service_id = params[:id]

    if service_id.nil?
      raise 'Bad input'
    end

    #
    @item = ClusterService.find(service_id)


    #
    @cluster = @item.cluster
    @user = @cluster.primary_admin

    @user_token = Gexcore::AuthService.get_new_token @user

    x = 0
  end

  def connect_webproxy
    # input

    @url = params[:url]
    @cluster_id = params[:cluster_id]

    #
    @cluster = Cluster.find(@cluster_id)
    @user = @cluster.primary_admin

    # services
    @webproxy_host = Gexcore::Settings.webproxy_host


    # set cookie
    @user_token = Gexcore::AuthService.get_new_token @user

    #
    cookies[:token] = {
        :value => @user_token,
        :expires => 1.year.from_now,
        :domain => @webproxy_host
    }

    #response.headers["Location"] = @url

    #head :found

    redirect_to @url+'?token='+@user_token
  end

end
