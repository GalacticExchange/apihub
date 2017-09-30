class Admin::LibraryApplicationsController < Admin::MyAdminBaseController

  include FilterHelper

  before_action :set_app, only: [:show, :edit, :update]

  autocomplete :library_application, :name, :full => true

# search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_library_applications_url, search_url: :search_admin_library_applications_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :q, :string,  :text, {label: 'Search all', default_value: '', ignore_value: '', condition: :empty, input_html: {style: "width: 130px"}}

    field :enabled, :int, :select, {
        label: 'Status',
        default_value: -1, ignore_value: -1,
        collection: FilterHelper.for_select_yes_no_enable_library_application
    }

    field :name, :string, :text, {label: 'Name', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}
    field :title, :string, :text, {label: 'Title', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}

  end

  def index
    #@items = LibraryApplication.by_filter(@filter)
    @items, @total = Gexcore::LibraryApplicationSearchService.search_by_filter(@filter)

    # download
    @versions = {}
    @versions_urls = {}
    @download_urls = {}
    @items.each do |item|
      @versions_urls[item.id] = (Gexcore::Applications::Service.app_url_version(item.name) rescue nil)
      @versions[item.id] = (Gexcore::Applications::Service.app_current_version(item.name) rescue nil)
      next unless @versions[item.id]

      @download_urls[item.id] = (Gexcore::Applications::Service.app_download_url(item.name, @versions[item.id]) rescue nil)
    end

  end

  ###

  def model
    LibraryApplication
  end

  ###
  def show
    #
    #@attachment = @item.application_images.build
  end

  def new
    @item = model.new
  end

  def create
    @item = model.new(app_create_params)

    respond_to do |format|
      if @item.save
        format.html { redirect_to admin_library_application_path(:id=>@item.id), notice: 'App was successfully created.' }
      else
        format.html { render :new }
      end
    end

  end

  def destroy
    @item = model.find(params[:id])
    @item.destroy
    respond_to do |format|
      format.html { redirect_to admin_library_applications_path, notice: 'App was successfully destroyed.' }
    end
  end


  def edit

  end

  def update

    @res = @item.update(app_params)

    respond_to do |format|
      if @res
        format.html {
          redirect_to admin_library_application_path, notice: 'Library Application was successfully updated'
        }
      else
        format.html { render :edit }
      end
    end
  end


  private

  def set_app
    application_id = params[:id]

    if application_id.nil?
      raise 'Bad input'
    end

    @item = model.find(application_id)
  end

  def app_create_params
    params.require(:library_application).permit(:title, :picture, :name, :pos, :enabled,
                                                :description, :company_name, :category_title,
                                                images_attributes: [:id, :image, :_destroy])
  end


  def app_params
    params.require(:library_application).permit(:company_name,:title, :picture, :category_title, :icon, :pos, :enabled, :description, images_attributes: [:id, :image, :_destroy])
  end

end
