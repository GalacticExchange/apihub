class Admin::LogTypesControllerOld < Admin::MyAdminBaseController

  include FilterHelper

  autocomplete :log_type, :name, :full => true

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
    @items = LogType.by_filter(@filter)
  end

  def new
    @log_type = LogType.new
  end

  def edit
    @log_type = LogType.find(params[:id])
  end

  def create
    # input
    @log_type = LogType.new(log_type_params)

    @res = @log_type.save

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
    @id = params[:id]

    @log_type = LogType.find(@id)

    @res = @log_type.update(log_type_params)

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

end

