class Admin::LogTypesController < Admin::MyAdminBaseController

  before_action :get_log_type_from_elastic, only: [:edit, :update]

  include FilterHelper

  #autocomplete :log_type, :name, :full => true

  def autocomplete_log_type_name

    q = params[:q]

    items = Gexcore::ElasticSearchHelpers.autocomplete_elastic_dsl_array_for_render_json(q.downcase, "LogType", ["name"])

    #
    render :json => items
    #render :json => Gexcore::Common.items_to_json(items, 'id', 'name')

  end

  # search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_log_types_url, search_url: :search_admin_log_types_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :visible_client, :int, :select, {
                     label: 'Status',
                     default_value: -1, ignore_value: -1,
                     collection: FilterHelper.for_select_yes_no_visible_client
                 }

    field :need_notify, :int, :select, {
                             label: 'Status',
                             default_value: -1, ignore_value: -1,
                             collection: FilterHelper.for_select_yes_no_need_notify
                         }
    field :name, :string, :text, {label: 'name', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}
  end


  def index
    page_num = params[:pg].to_i
    #
    Gexcore::LogTypeSearchService.set_pagin_filter(@filter, page_num)
    #
    @total, @records = Gexcore::LogTypeSearchService.search_by_filter(@filter)
    # paginate arry with kaminari
    @kaminary_arr = Kaminari.paginate_array(@records).page(page_num).per(1)
  end

  def new
    @log_type = {}
  end

  def edit
    @edit
  end

  def create
    # input
    params_hash = log_type_params.each {|t| t}

    @res = Gexcore::LogTypeSearchService.create_or_update_log_type_in_elasticsearch(nil, params_hash)

    respond_to do |format|
      if @res

        format.html {
          #redirect_to @user, notice: 'User was successfully created.'
          redirect_to admin_log_types_path, notice: 'Congratulations! You just create log type!'
        }

      else
        format.html {
          render :new
        }

      end
    end
  end

  def update

    params_hash = log_type_params.each {|t| t}

    @res = Gexcore::LogTypeSearchService.create_or_update_log_type_in_elasticsearch(@log_type['_id'], params_hash)


    respond_to do |format|
      if @res
        format.html {
          redirect_to admin_log_types_path, notice: 'Congratulations! You just edit log type!'
        }
        #format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def log_type_params
    params.require(:log_type).permit(:name, :description, :title, :enabled, :visible_client, :need_notify)
  end

  def get_log_type_from_elastic
    id = params[:id]
    @log_type = Gexcore::LogFromElasticsearch.log_type_search_by_id_or_name(id, nil)
  end

end

