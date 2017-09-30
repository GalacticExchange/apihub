class Admin::MessagesController < Admin::MyAdminBaseController

# search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_messages_url, search_url: :search_admin_messages_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    field :dialog, :string, :autocomplete, {label: 'dialog', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_message_dialog_name_admin_message_dialogs_path, input_html: {style: "width: 180px"}}
    field :from_user, :string, :autocomplete, {label: 'From user', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_user_username_admin_users_path, input_html: {style: "width: 180px"}}
    field :to_user, :string, :autocomplete, {label: 'To user', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_user_username_admin_users_path, input_html: {style: "width: 180px"}}

  end

  def index

    @items = Message.includes(:message_dialog, :from_user, :to_user).by_filter(@filter)

  end



end


