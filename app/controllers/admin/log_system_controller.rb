#class Admin::LogSystemController < Optimacms::Admin::AdminBaseController
class Admin::LogSystemController < Admin::MyAdminBaseController

  # search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_log_system_index_url, search_url: :search_admin_log_system_index_url , search_action: :search} do
    default_order "id", 'desc'

    # fields

    field :type, :string,  :autocomplete, {label: 'Type', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_log_type_name_path, input_html: {style: "width: 150px"}}
    field :user, :string,  :autocomplete, {label: 'User', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_user_username_path, input_html: {style: "width: 150px"}}
    field :team, :string,  :autocomplete, {label: 'Team', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_team_name_path, input_html: {style: "width: 150px"}}
    field :cluster, :string,  :autocomplete, {label: 'Cluster', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_cluster_name_path, input_html: {style: "width: 150px"}}
    field :node, :string,  :autocomplete, {label: 'Node', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_node_name_path, input_html: {style: "width: 180px"}}

  end


  def index
    @filter.set_order 'id', 'desc'
    @items = LogSystem.by_filter(@filter).includes(:log_type, :user, :team, :cluster, :node)
    @levels = LogSystem::LEVELS.invert
  end

end

