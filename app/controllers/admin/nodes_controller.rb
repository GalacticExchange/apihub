class Admin::NodesController < Admin::MyAdminBaseController

  #autocomplete :node, :name, :full => true
  def autocomplete_node_name

    q = params[:q]

    items = Gexcore::ElasticSearchHelpers.autocomplete_elastic_dsl_array_for_render_json(q.downcase, "Node", ["name"])

    #
    #render :json => Gexcore::Common.items_to_json(items, 'id', 'name')
    render :json => items
  end

# search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_nodes_url, search_url: :search_admin_nodes_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :status, :int, :select, {
                     label: 'Status',
                     default_value: -1, ignore_value: -1,
                     collection: Node.for_filter_statuses
                 }

    field :cluster, :string, :autocomplete, {label: 'Cluster', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_cluster_name_admin_clusters_path, input_html: {style: "width: 180px"}}
    field :name, :string, :text, {label: 'Name', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}
    field :uid, :string, :text, {label: 'UID', default_value: '', condition: :like_full, input_html: {style: "width: 200px"}}
  end

  def index
    @cluster_id = params[:cluster_id]

    if @cluster_id
      @cluster = Cluster.find(@cluster_id)

      if @cluster
        @filter.set 'cluster_id', @cluster_id
        @filter.set 'cluster', @cluster.name
      end

    end

    @items = Node.includes(:cluster => [:team]).by_filter(@filter)

    # for count
    #node_ids = @items.ids
    #node_ids = Node.pluck(:id)

    node_ids = @items.map(&:id)
    @containers_count = ClusterContainer.where(:node_id => node_ids).group(:node_id).count
  end

  def show
    node_id = params[:id]

    if node_id.nil?
      raise 'bad input'
    end

    #
    @item = Node.find(node_id)


    # consul info
    @info_consul = Gexcore::Consul::Service.get_node_data(@item)


    # some info
    @sshproxy_host = Gexcore::Settings.sshproxy_host
    @webproxy_host = Gexcore::Settings.webproxy_host

    # services
    #@services_hadoop = Gexcore::ClusterServices::Service.get_service_list({cluster_id: @item.cluster_id, node_id: @item.id})


    # containers
    @containers = @item.containers.all

  end

  def send_command

    @node = Node.find(params[:id])
    @cmd = params[:cmd]

    if @cmd=='provision_remove_node'
      @res = Gexcore::Nodes::Provision.provision_master_uninstall_node(@node, {})
    elsif @cmd=='operation_remove'
      @res = Gexcore::Nodes::Service.remove_node(@node)

    else
      @res = Gexcore::Nodes::Control.do_action_with_node(@node, @cmd)
    end



    respond_to do |format|
      format.html {      }
      format.json{        render :json=>@res      }

    end
  end


  def get_info_containers
    @node = Node.find(params[:id])

    @res = Gexcore::Nodes::Service.get_node_info_all(@node)

    respond_to do |format|
      format.html {

      }
      format.json{
        render :json=>@res
      }
    end
  end

end
