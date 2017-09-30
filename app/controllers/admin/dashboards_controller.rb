class Admin::DashboardsController < Admin::MyAdminBaseController

  before_action :get_dashboard, only: [:edit, :update]

  # search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_dashboards_url, search_url: :search_admin_dashboards_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :name, :string, :text, {label: 'Name', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}
    field :title, :string, :text, {label: 'Title', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}
    field :cluster, :string, :autocomplete, {label: 'Cluster', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_cluster_name_admin_clusters_path, input_html: {style: "width: 180px"}}
    #field :user, :string,  :autocomplete, {label: 'User', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_user_username_admin_users_path, input_html: {style: "width: 150px"}}

  end

  def index
    @cluster_id = params[:cluster_id]
    #@user_id = params[:user_id]

    if @cluster_id
      @cluster = Cluster.find(@cluster_id)
      @filter.set 'cluster_id', @cluster_id
      @filter.set 'cluster', @cluster.name

    end
=begin
    if @user_id
      @node = User.find(@user_id)
      @filter.set 'user_id', @user_id
      @filter.set 'user', @user.username
    end
=end
    @items = Dashboard.includes(:cluster).by_filter(@filter)

  end

  def show
  end

  def new
    @cluster_id = params[:cluster_id]
    @item = Dashboard.new(cluster_id: @cluster_id)
  end

  def edit
  end

  def create
    # input
    @item = Dashboard.new(dashboards_params)
    @res = @item.save

    respond_to do |format|
      if @res

        format.html {
          #redirect_to @user, notice: 'User was successfully created.'
          redirect_to admin_dashboards_path(cluster_id: @item.cluster_id), notice: 'Congratulations! You just create dashboard!'
        }

      else
        format.html {
          render :new
        }

      end
    end
  end

  def update

    @res = @item.update(dashboards_params)

    respond_to do |format|
      if @res
        format.html {
          redirect_to admin_dashboards_path(cluster_id: @item.cluster_id), notice: 'Congratulations! You just edit dashboard!'
        }
        #format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def dashboards_params
    params.require(:dashboard).permit(:name, :enabled, :title, :cluster_id, :pos, :content)
  end

  def get_dashboard
    id = params[:id]
    @item = Dashboard.find id
  end


end
