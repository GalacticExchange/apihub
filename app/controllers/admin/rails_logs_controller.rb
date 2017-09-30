class Admin::RailsLogsController < Admin::MyAdminBaseController

  def index

  end

  def get_logs
    name = params[:name]
    send "show_logs_#{name}"
  end

  def show_logs_logs
    path = File.join(Rails.root, 'log', Rails.env + ".log")

    @text = `tail -n 2000 #{path}`

    render :template => "admin/rails_logs/show_logs_logs.html.haml"
  end

  def show_logs_sq_logs
    path = File.join(Rails.root, 'log',"apihub-sidekiq-" + Rails.env + "-all_nolog-0.log")
    @text = `tail -n 2000 #{path}`

    render :template => "admin/rails_logs/show_logs_sq_logs.html.haml"
  end

  def show_logs_d_sd_logs
    path = File.join(Rails.root, 'log',"apihub-sidekiq-" + Rails.env + "-log-0.log")
    @text = `tail -n 2000 #{path}`

    render :template => "admin/rails_logs/show_logs_d_sd_logs.html.haml"
  end

end