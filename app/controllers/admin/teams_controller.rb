class Admin::TeamsController < Admin::MyAdminBaseController

  autocomplete :team, :name, :full => true

# search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_teams_url, search_url: :search_admin_teams_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :status, :int, :select, {
                     label: 'Status',
                     default_value: -1, ignore_value: -1,
                     collection: Team.for_filter_statuses
                 }

    field :name, :string, :text, {label: 'name', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}
  end

  def show
    id = params[:id]
    if id.nil?
      raise 'Bad input'
    end
    @team = Team.find id
  end

  def index

    @items = Team.by_filter(@filter)

    #team_ids = Team.pluck(:id)


    team_ids = @items.map(&:id)

    @users_count = User.where(:team_id => team_ids).group(:team_id).count
    @clusters_count = Cluster.where(:team_id => team_ids).group(:team_id).count
    @invitations_count = Invitation.where(:team_id => team_ids).group(:team_id).count

  end

end
