class Admin::ClusterContainersController < Admin::MyAdminBaseController

  autocomplete :cluster_container, :name, { :display_value => 'name_with_cluster_name', :full_model=>true }

# search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_cluster_containers_url, search_url: :search_admin_cluster_containers_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :cluster, :string, :autocomplete, {label: 'Cluster', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_cluster_name_admin_clusters_path, input_html: {style: "width: 180px"}}
    field :node, :string, :autocomplete, {label: 'Node', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_node_name_admin_nodes_path, input_html: {style: "width: 180px"}}
    field :application, :string, :autocomplete, {label: 'Application', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_cluster_application_name_admin_cluster_applications_path, input_html: {style: "width: 180px"}}

  end

  def index
    @cluster_id = params[:cluster_id]
    @node_id = params[:node_id]
    @application_id = params[:application_id]

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

    @items = ClusterContainer.includes(:node, :application, :cluster).by_filter(@filter)

    ids = @items.map(&:id)

    # counts
    @count_services = ClusterService.where(:container_id => ids).group(:container_id).count
    

  end

  def show
    container_id = params[:id]

    if container_id.nil?
      raise 'Bad input'
    end

    #
    @item = ClusterContainer.find(container_id)

    # some data
    @user_token = Gexcore::AuthService.get_new_token(@item.cluster.team.primary_admin)
  end


end
