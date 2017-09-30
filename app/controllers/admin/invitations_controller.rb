class Admin::InvitationsController < Admin::MyAdminBaseController

# search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_invitations_url, search_url: :search_admin_invitations_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :status, :int, :select, {
                     label: 'Status',
                     default_value: -1, ignore_value: -1,
                     collection: Invitation.for_filter_statuses
                 }
    field :invitation_type, :int, :select, {
                     label: 'Types',
                     default_value: -1, ignore_value: -1,
                     collection: Invitation.for_filter_types
                 }
    field :team, :string, :autocomplete, {label: 'Team', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_team_name_admin_teams_path, input_html: {style: "width: 180px"}}
    field :from_user, :string, :autocomplete, {label: 'User', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_user_username_admin_users_path, input_html: {style: "width: 180px"}}
    field :cluster, :string, :autocomplete, {label: 'Cluster', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_cluster_name_admin_clusters_path, input_html: {style: "width: 180px"}}
    field :uid, :string, :text, {label: 'UID', default_value: '', condition: :like_full, input_html: {style: "width: 200px"}}

  end

  def index
    @cluster_id = params[:cluster_id]
    @team_id = params[:team_id]
    @from_user_id = params[:from_user_id]

    if @cluster_id
      @cluster = Cluster.find(@cluster_id)
      @filter.set 'cluster_id', @cluster_id
      @filter.set 'cluster', @cluster.name

    end

    if @team_id
      @team = Team.find(@team_id)
      @filter.set 'team_id', @team_id
      @filter.set 'team', @team.name

    end

    if @from_user_id
      @user = User.find(@from_user_id)
      @filter.set 'from_user_id', @from_user_id
      @filter.set 'from_user', @user.username

    end

    @items = Invitation.includes(:cluster, :user, :team).by_filter(@filter)

  end

end
