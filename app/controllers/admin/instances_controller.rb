class Admin::InstancesController < Admin::MyAdminBaseController

  before_action :set_item, only: [:show, :edit_admin_notes, :update_admin_notes]
  #
  #autocomplete :instance, :uid, :full => true
#=begin
  def autocomplete_instance_uid
    #
    q = params[:q]
    #              c02d6bcb-9a87-46cc-8df6-fad3234bedc9
    items = Gexcore::ElasticSearchHelpers.autocomplete_elastic_dsl_array_for_render_json(q.downcase, "Instance", ["uid"])
    #
    render :json => items
    #render :json => Gexcore::Common.items_to_json(items, 'id', 'uid')
  end
#=end
  # search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_instances_url, search_url: :search_admin_instances_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :uid, :string, :text, {label: 'UID', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}
  end

  def index
    @items = Instance.by_filter(@filter)
  end

  def show
  end

  def edit_admin_notes
  end

  def update_admin_notes
    @res = @item.update(admin_notes_params)
    respond_to do |format|
      if @res
        format.html {
          redirect_to admin_instance_path(@item)
        }
        #format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :show }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_item
    item_id = params[:id]
    if item_id.nil?
      raise 'Bad input'
    end
    @item = Instance.find(item_id)
  end

  def admin_notes_params
    params.require(:instance).permit(:admin_notes)
  end

end
