class Admin::MessageDialogsController < Admin::MyAdminBaseController

  #autocomplete :cluster, :name, :full => true
  def autocomplete_message_dialog_name
    q = params[:q]
    options = {}

    if q && q.present?
      users = get_autocomplete_items(:model => User, :options => options, :q => q, :method => 'username')

      user_ids = users.ids#User.pluck(:id)

      dialogs_ids = MessageDialog.where("from_user_id in (?) OR to_user_id in (?)", user_ids, user_ids)
      #items = MessageDialog.where_for_user(q).all
      #items = Message.where(:dialog_id => dialogs_ids)
    elsif params[:q].nil?
      # return ALL
      #items = get_autocomplete_items(:model => MessageDialog, :options => options, :q => '', :method => 'from_user_id')
    end

    res = items.collect do |item|

      [item.id.to_s, item.from_user.username.to_s, item.to_user.username]
    end

    render :json => res
  end



# search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_clusters_url, search_url: :search_admin_clusters_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :team_id, :int, :empty, {default_value: 0}

    field :team, :string, :autocomplete, {label: 'Team', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_team_name_admin_teams_path, input_html: {style: "width: 180px"}}

    field :name, :string, :text, {label: 'Name', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}
  end

  def index
    @team_id = params[:team_id]

    if @team_id
      @team = Team.find(@team_id)
      @filter.set 'team_id', @team_id
    end

    @items = Cluster.includes(:team).by_filter(@filter)

  end

end