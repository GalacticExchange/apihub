module Utrack
  class YoutrackService
    require "youtrack"

    def self.login
      client = Youtrack::Client.new do |c|
        c.url = Rails.application.secrets.youtrack_url
        c.login = Rails.application.secrets.youtrack_login
        c.password = Rails.application.secrets.youtrack_password
      end
      client.connect!
      client
    end

    def self.get_projects_by_client client
      client.projects
    end

    def self.get_issues_resource projects, project_name, filter
      projects.get_issues_for(project_name, 5000, filter)
    end

    def self.get_issues_list projects, project_name, filter
      issues_res = get_issues_resource projects, project_name, filter
      issues_res['issues']['issue'] if issues_res['issues']
    end

    def self.get_customers(filter)
      project_name = 'CUSTOMERS'
      client = login
      projects = get_projects_by_client client
      get_issues_list projects, project_name, filter
    end

    def self.get_field_val_by_name(fields, field_name)
      field = fields.select{ |item| item['name'] == field_name }
      field[0]['value'] if field.length > 0
    end

    def self.get_issue_id_by_username(project_name,username)
      user = get_issue_by_username(project_name,username)
      user["id"] if user
    end

    def self.get_issue_by_id(issue_id)
      client = login
      issue_resource = client.issues
      issue_resource.find(issue_id)
    end

    def self.get_issue_by_username(project_name,username)
      filter = "Username: #{username}"
      client = login
      projects = get_projects_by_client client
      get_issues_list(projects, project_name, filter)
    end

    def self.update_user_in_db(user, user_hash)
      user.customer_info = user_hash.to_json
      user.customer_info_updated = Time.now
      user.save
    end

    def self.loaded_comment(issue_resource,yt_id,u_id)
      user_page = Gexcore::Settings.domain + '/admin/users/' + u_id.to_s
      comment = "Customer info loaded in DB. Date: #{Time.now.strftime("%d/%m/%Y %H:%M")}. User page: #{user_page}"
      issue_resource.add_comment(yt_id, comment: comment)
    end

    def self.load_customers(customers, force)

      client = login
      issue_resource = client.issues
      updated_users = 0

      customers.each do |customer|
        username = get_field_val_by_name customer['field'], 'Username'
        user = User.get_by_username(username)

        if user && (force || user.customer_info.nil?)
          update_user_in_db(user, customer)
          loaded_comment(issue_resource,customer['id'],user.id)
          updated_users += 1
        end

      end
      updated_users if customers
    end

    def self.update_by_username(username)
      project_name = "CUSTOMERS"
      customer = get_issue_by_username(project_name,username)

      username = get_field_val_by_name customer['field'], 'Username'
      user = User.get_by_username(username)

      if user
        update_user_in_db(user, customer)
        client = login
        issue_resource = client.issues
        loaded_comment(issue_resource,customer['id'],user.id)
      end

    end

    def self.update_all_users force
      filter = "Username: -{No username}"
      customers = get_customers(filter)
      load_customers(customers, force)
    end

  end
end




# Please, check your Settings page in Admin menu - "Max Issues to Export" parameter should be set to issues count that you actually need.
# only users with usernames: Username: -{No username}
