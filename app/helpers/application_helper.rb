module ApplicationHelper

  #TODO: move from app helper
  def any_items(items_array)
    items_array.length != 0
  end


  def status_color(status)
    case status
      when "active", "running"
        return 'green'
      when "install_error", "start_error", "restart_error", "stop_error", "remove_error", "uninstall_error", "not_installed", "disconnected"
        return 'red'
      when "installing", "starting", "stopping", "removing", "uninstalling", "restarting"
        return 'orange'
      when "installed", "removed", "uninstalled", "stopped", "deleted"
        return 'yellow'
    end
  end


  def hint_text

    case @page_selected

      #workspace part
      when 'stats'
        return 'Use this page to view statistics'
      when 'nodes'
        return 'Use this page to manage nodes'
      when 'shares'
        return 'Use this page to ....'
      when 'logs'
        return 'Use this page to .....'
      when 'cluster'
        return 'Use this page to ....'


      #profile part
      when 'edit'
        return 'Use this page to ....'
      when 'edit_avatar'
        return 'Use this page to ....'
      when 'edit_team'
        return 'Use this page to ....'
      when 'edit_pass'
        return 'Use this page to ....'


      #team part
      when 'team_members'
        return 'Use this page to ....'
      when 'team_invitations'
        return 'Use this page to ....'
      when 'team_edit'
        return 'Use this page to ....'


    end

  end




  def nl2br(s)
    s.gsub(/\n/, '<br>')
  end

  def website_page(u)
    return Gexcore::Settings.website_url+''+u
  end

  def our_date(time)
    time.strftime("%d %h %Y")
  end

  def our_date_message(time)
    time.strftime("%d %h %Y %H:%M:%S")
  end


  def avatar_url(user, type)
    if user.avatar.present?
      user.avatar.url(type.to_sym)
    else
      gravatar_id = Digest::MD5.hexdigest(user.email.downcase)
      #gravatar_id = user.email.downcase
      if type.to_sym == :medium
        s = 200
      elsif type.to_sym == :thumb
        s= 100
      end
      "http://gravatar.com/avatar/#{gravatar_id}.png?s=#{s}&d=retro"
    end
  end

  # for library_application
  def picture_url_library_application(application, type)
    if application.picture.present?
      application.picture.url(type.to_sym)
    else
      "No picture"
    end
  end

  def icon_url_library_application(application, type)
    if application.icon.present?
      application.icon.url(type.to_sym)
    else
      "No icon"
    end
  end


  # for library_application_images
  def picture_url_library_application_image(application, type)
    if application.image.present?
      application.image.url(type.to_sym)
    else
      "No picture"
    end
  end

  def avatar_url_team(team, type)
    if team.avatar.present?
      team.avatar.url(type)
    else
      gravatar_id = Digest::MD5.hexdigest(team.name.downcase)
      if type.to_sym == :medium
        s = 200
      elsif type.to_sym == :thumb
        s= 100
      end
      "http://gravatar.com/avatar/#{gravatar_id}.png?s=#{s}&d=retro"
    end
  end

  def vertical_simple_form_for(resource, options = {}, &block)
    options[:html] ||= {}

    # class
    options[:html][:class] ||= []
    if options[:html][:class].is_a? Array
      options[:html][:class] << 'form-vertical'
    else
      options[:html][:class] << ' form-vertical'
    end
    options[:html][:role] = 'form'


    options[:wrapper] = :vertical_form
    options[:wrapper_mappings] = {
        check_boxes: :vertical_radio_and_checkboxes,
        radio_buttons: :vertical_radio_and_checkboxes,
        file: :vertical_file_input,
        boolean: :vertical_boolean
    }

    simple_form_for(resource, options, &block)
  end


end
