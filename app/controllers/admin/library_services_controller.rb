class Admin::LibraryServicesController < Admin::MyAdminBaseController

  before_action :set_serv, only: [:show, :edit, :update]

  autocomplete :library_service, :name, :full => true

# search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_library_services_url, search_url: :search_admin_library_services_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :name, :string, :text, {label: 'Name', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}
    field :title, :string, :text, {label: 'Title', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}

  end

  def index

    @items = LibraryService.by_filter(@filter)

  end

  def show

  end


  def new
    @item = LibraryService.new
  end

  def create
    @item = LibraryService.new(serv_params)

    respond_to do |format|
      if @item.save
        format.html { redirect_to admin_library_service_path(:id=>@item.id), notice: 'Service was successfully created.' }
      else
        format.html { render :new }
      end
    end

  end

  def destroy
    @item = LibraryService.find(params[:id])
    @item.destroy
    respond_to do |format|
      format.html { redirect_to admin_library_services_path, notice: 'Service was successfully destroyed.' }
    end
  end


  def edit

  end

  def update

    @res = @item.update(serv_params)

    respond_to do |format|
      if @res
        format.html {
          redirect_to admin_library_service_path, notice: 'Library Service was successfully updated'
        }
      else
        format.html { render :edit }
      end
    end
  end


  private

  def set_serv
    service_id = params[:id]

    if service_id.nil?
      raise 'Bad input'
    end

    @item = LibraryService.find(service_id)
  end

  def serv_params
    params.require(:library_service).permit(:title, :name)
  end

end
