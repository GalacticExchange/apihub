module Gexcore::Log
  class Slack < Gexcore::BaseService

    LONG_LINE = '--------------------------------------------------------------------------------------------------'

    COLORS = {
        gex: '1d87e4',
        green: '#00C853',
        red: '#c30000',
        orange: '#1d87e4'
    }

    #old
    @@gex_col = '#1d87e4'
    @@green_col = '#00C853'
    @@red_col = '#c30000'
    @@orange_col = '#1d87e4'

    def self.get_client
      ::Slack::Web::Client.new
    end

    def self.get_actions_channel
      Rails.application.secrets.slack_notif_channel
    end

    def self.get_errors_channel
      Gexcore::Settings.log_slack_channel
    end

    def self.error_to_slack(e)

      return nil if !e || Rails.env.test?

      log_params = { }
      log_params[:type] = e[:type_name] if e[:type_name]
      log_params[:node_id] = e[:node_id]
      log_params[:cluster_id] = e[:cluster_id] if e[:cluster_id]
      log_params[:team_id] = e[:team_id] if e[:team_id]

      ex_title = "Exception at #{Time.now}"
      ex_message_content = get_ex_message_content(e, ex_title)

      mess = return_att_ex(LONG_LINE, ex_title, '', "API Error", @@red_col, log_params, ex_message_content)
      web_client = get_client
      channel = get_errors_channel

      send_message(web_client, channel, mess)

      ex_message_content[:files].each do |file|
        send_file(web_client, channel, file[:filename], file[:content])
      end
    end


    def self.user_created(user)

      return nil if !user || Rails.env.test?

      mess = user_created_template(user)
      web_client = get_client
      channel = get_actions_channel

      send_message(web_client, channel, mess)
    end

    def self.cluster_created(cluster)

      return nil if !cluster || Rails.env.test?

      mess = cluster_created_template(cluster)
      web_client = get_client
      channel = Rails.application.secrets.slack_notif_channel

      send_message(web_client, channel, mess)
    end

    def self.node_created(node)

      return nil if !node || Rails.env.test?

      mess = node_created_template(node)
      web_client = get_client
      channel = get_actions_channel

      send_message(web_client, channel, mess)
    end

    def self.send_file(web_client,channel, filename, content)
      web_client.files_upload(filename: filename, channels: channel, content: content)
    end

    def self.send_message(web_client, channel, message)
      if message[:type]==:text
        web_client.chat_postMessage(channel: channel, as_user: true, text: message[:text])
      else
        web_client.chat_postMessage(channel: channel, as_user: true, attachments: message[:att])
      end
    end

    def self.ex_template(ex)
      info = get_ex_str(ex)
      fallback = "API Error"
      return_att('API Error :exclamation:', "API Exception #{Time.now}", info, fallback, @@red_col)
    end


    def self.user_created_template(user)
      info = get_user_str(user)
      country = user.country.upcase rescue nil
      fallback = "New user: #{user.username}"
      return_att('User created :upside_down_face: :white_check_mark:', "#{user.firstname} #{user.lastname}, #{country}", info, fallback, @@gex_col)
    end


    def self.cluster_created_template(cluster)
      info = get_cluster_str(cluster)
      type = cluster.cluster_type.name rescue nil
      fallback = "New cluster: #{cluster.name}"
      return_att('Cluster created  :rocket:', "#{cluster.name}, #{type}", info, fallback, @@gex_col)
    end

    def self.node_created_template(node)
      info = get_node_str(node)
      fallback = "New node: #{node.name}"
      return_att('Node created  :sparkles:', "#{node.name}", info, fallback, @@gex_col)
    end


    def self.get_ex_message_content(ex, ex_title)
      fields = []
      files = []

      data = JSON.parse(ex[:data]) rescue ex[:data]
      data.each do |name, val|
        next if val.nil?
        value = ''

        if val.kind_of?(Array) || val.kind_of?(Hash)
           val.each{|ln| value += "#{ln} \n"}
        else
          value = val
        end

        if value.to_s.length > 1000
          files << {filename: "Attachment to #{ex_title} - #{name}", content: value}
          fields << {title: name, value: "Field is too long. See attachment.", short: true}
          next
        end

        short = (value.to_s.length > 34) ? false : true
        fields << {title: name, value: value, short: short}
      end

      {fields: fields, files: files}
    end


    # todo: old
    def self.get_ex_str(ex)
      <<-EOF
        Date: #{ex[:date]} 
        Message: #{ex[:message]}
        Source: #{ex[:source]}
        Type: #{ex[:type]}
        User: #{ex[:user]}
        Data: #{ex[:data]}
      EOF
    end

    def self.get_user_str(user)
      <<-EOF
        Info:
        Username: #{user.username}
        Full name: #{user.firstname} #{user.lastname}
        Email: #{user.email}
        Phone: #{user.phone_number}
        Country: #{user.country}
        Registration IP: #{user.registration_ip}
        Team: #{user.team.name}
      EOF
    end


    def self.get_cluster_str(cluster)
      <<-EOF
        Info:
        Name: #{cluster.name}
        Admin: #{cluster.primary_admin.username}
        Team: #{cluster.team.name}
        Type: #{cluster.cluster_type.name}
      EOF
    end

    def self.get_node_str(node)
      <<-EOF
        Info:
        Name: #{node.name}
        Cluster: #{node.cluster.name}, #{node.cluster.cluster_type.name}
        Admin: #{node.cluster.primary_admin.username}
        Team: #{node.cluster.team.name}
      EOF
    end


    def self.add_param(url, param_name, param_value)
      require 'uri'
      uri = URI(url)
      params = URI.decode_www_form(uri.query || "") << [param_name, param_value]
      uri.query = URI.encode_www_form(params)
      uri.to_s
    end


    def self.get_log_url(params=nil)

      log_url = File.join(Gexcore::Settings.domain, 'admin/log_debug')

      if params
        log_url = add_param(log_url, 'filter_cmd', 'set')

        params.each do |name, val|
          log_url = add_param(log_url, name, val.to_s)
        end
      end

      log_url
    end

    def self.return_att_ex(pre_text, title, text, fallback, color, log_params, ex_message_content)

      log_url = get_log_url(log_params)

      {
          :type => :att,
          :att =>
              [{
                   title: title,
                   title_link: log_url,
                   fields: ex_message_content[:fields],
                   pretext: pre_text,
                   text: text,
                   color: color,
                   fallback: fallback
               }]
      }
    end

    def self.return_att(pre_text, title, text, fallback, color)
      {
          :type => :att,
          :att =>
              [{
                   pretext: pre_text,
                   title: title,
                   text: text,
                   color: color,
                   fallback: fallback
               }]
      }
    end

    def return_mess(text)
      {
          :type => :mess,
          :text => text
      }
    end

    def self.send_exception_to_slack(e)
      ex_attachment = {
          fallback: "Exception_message",
          text: "#{e}  #{e.backtrace}",
          color: "#ffff00"
      }
      notifier = ::Slack::Notifier.new "https://hooks.slack.com/services/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", channel: "#main_errors", username: "e"

      notifier.post(text: "Exception #{Time.now}", attachments: ex_attachment)
    end

  end
end
