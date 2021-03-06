class Admin::LogDbController < Admin::MyAdminBaseController

# search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_log_db_index_url, search_url: :search_admin_log_db_index_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :q, :string,  :text, {label: 'Search all', default_value: '', ignore_value: '', condition: :empty, input_html: {style: "width: 130px"}}

    field :min_level, :int,  :select, {
        label: 'Level',
        default_value: 0, ignore_value: 0,
        collection: Gexcore::LogLevel.get_all_with_blank, label_method: :name, value_method: :id,
        condition: :custom, condition_where: 'level >= ?'
    }
    field :source, :string,  :autocomplete, {label: 'Source', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_log_source_name_admin_log_sources_path, input_html: {style: "width: 150px"}}
    field :type, :string,  :autocomplete, {label: 'Type', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_log_type_name_admin_log_types_path, input_html: {style: "width: 150px"}}
    field :user, :string,  :autocomplete, {label: 'User', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_user_username_admin_users_path, input_html: {style: "width: 150px"}}
    field :team, :string,  :autocomplete, {label: 'Team', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_team_name_admin_teams_path, input_html: {style: "width: 150px"}}
    field :cluster, :string,  :autocomplete, {label: 'Cluster', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_cluster_name_admin_clusters_path, input_html: {style: "width: 150px"}}
    field :node, :string,  :autocomplete, {label: 'Node', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_node_name_admin_nodes_path, input_html: {style: "width: 180px"}}
    field :ip, :string,  :text, {label: 'IP', default_value: '', ignore_value: '', input_html: {style: "width: 80px"}}
    field :instance, :string,  :autocomplete, {label: 'Instance', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_instance_uid_admin_instances_path, input_html: {style: "width: 100px"}}
    field :date_from, :string,  :text, {label: 'Date', default_value: '', condition: :custom, condition_where: 'created_at >= ?', input_html: {style: "width: 300px"}}#, input_html: {"data-date-options" => "{\"locale\":\"en\",\"dayViewHeaderFormat\":\"MMMM YYYY\",\"format\":\"YYYY-MM-DD HH:mm\"}", :name => "filter[date_from]", :type => "text", :placeholder => "Date", :style => "width: 180px", :value => ""}}
    field :date_to, :string,  :text, {label: 'to', default_value: '', condition: :custom, condition_where: 'created_at <= ?'}

  end

  def index
    #page_num = params[:pg].to_i
    #Gexcore::LogDebugSearchService.set_date_and_pagin_filter(@filter, page_num)

    #
    @items = LogDebug.by_filter(@filter)

    # paginate arry with kaminari
    #@kaminary_arr = Kaminari.paginate_array(@records).page(page_num).per(1)

  end

  def show_data
    id = params[:id]
    @item = LogDebug.find(id)
    @show_mode = params[:show] || ''
    respond_to do |format|
      format.html{
        if @show_mode=='modal'
          render :layout => false
        else

        end
      }
      format.json { render @item}
    end
  end

end

