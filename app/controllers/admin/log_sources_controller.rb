class Admin::LogSourcesController < Admin::MyAdminBaseController

  include FilterHelper

  autocomplete :log_source, :name, :full => true

  # search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_log_sources_url, search_url: :search_admin_log_sources_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :name, :string, :text, {label: 'name', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}
  end


  def model
    LogSource
  end

  def index
    @items = model.by_filter(@filter)
  end

  def new
    @item = model.new
  end

  def edit
    @item = model.find(params[:id])
  end

  def create
    # input
    @item = model.new(item_params)

    @res = @item.save

    respond_to do |format|
      if @res

        format.html {
          redirect_to admin_log_sources_path, notice: 'Saved!'
        }

      else
        format.html {
          render :new
        }

      end
    end
  end

  def update
    @item = model.find(params[:id])

    @res = @item.update(item_params)

    respond_to do |format|
      if @res
        format.html {
          redirect_to admin_log_sources_path, notice: 'Saved!'
        }
        #format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def item_params
    params.require(:log_sources).permit(:name, :description, :title, :enabled)
  end

end

