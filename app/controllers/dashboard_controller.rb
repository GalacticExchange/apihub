class DashboardController < AccountBaseController

  layout 'simple'

  def index
    if [Group.group_user.id].include? current_user.group_id
      return index_user
    else
      return index_admin
    end
  end

  def no_cluster
    render "dashboard/no_cluster" and return
  end


  def index_admin
    init_cluster

    return no_cluster unless @current_cluster


    current_dashboard = @current_cluster.dashboards[0]

    if current_dashboard
      @dashboard = Gexcore::Dashboards::Service.load_dashboard(current_dashboard)
    end


    render "dashboard/index_admin"
  end

  def index_user
    init_cluster
    return no_cluster unless @current_cluster


    current_dashboard = @current_cluster.dashboards[0]

    if current_dashboard
      @dashboard = Gexcore::Dashboards::Service.load_dashboard(current_dashboard)
    end

    render "dashboard/index_user" and return
  end

end
