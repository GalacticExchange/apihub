
Paperclip.interpolates :app_name do |attachment, style|
  if attachment.instance.instance_of? LibraryApplication
    attachment.instance.name
  elsif attachment.instance.instance_of? ApplicationImage
    attachment.instance.library_application.name
  end

end

Paperclip.interpolates :my_file_name do |attachment, style|
  attachment.instance.my_file_name
end

Paperclip.interpolates :user_username do |attachment, style|
  attachment.instance.username
end

Paperclip.interpolates :team_name do |attachment, style|
  attachment.instance.name
end
