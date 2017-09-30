class HomeController < AccountBaseController
  layout 'application'


  def index
    if current_user
      # user
      if [Group.group_user.id].include? current_user.group_id
        redirect_to dashboard_path and return
      end
      # admin
      if !@current_cluster
        if @all_clusters_w_shared.nil? || @all_clusters_w_shared.empty?
          redirect_to NgRoutes::CLUSTERS_NEW_WIZARD, :status => 302 and return
        else
          redirect_to NgRoutes::CLUSTERS, :status => 302 and return
        end
      else
        redirect_to NgRoutes::CLUSTER_STATISTIC.gsub('{cluster_id}', @current_cluster.uid), :status => 302 and return
      end
    else
      redirect_to new_user_session_path, :status => 302 and return
    end

  end


  def index_logged
    @no_footer = true
  end


end
