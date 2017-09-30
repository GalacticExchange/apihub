class Admin::ClustersController < Admin::MyAdminBaseController

  #autocomplete :cluster, :name, :full => true
  def autocomplete_cluster_name

    q = params[:q]

    items = Gexcore::ElasticSearchHelpers.autocomplete_elastic_dsl_array_for_render_json(q.downcase, "Cluster", ["name"])

    render :json => items
    #render :json => Gexcore::Common.items_to_json(items, 'id', 'name')

  end

# search
  search_filter :index, {save_session: true, search_method: :post_and_redirect, url: :admin_clusters_url, search_url: :search_admin_clusters_url , search_action: :search} do
    default_order "id", 'desc'

    # fields
    # fields
    field :status, :int, :select, {
                     label: 'Status',
                     default_value: -1, ignore_value: -1,
                     collection: Cluster.for_filter_statuses
                 }

    field :team, :string, :autocomplete, {label: 'Team', default_value: '', ignore_value: '', search_by: :id, :source_query => :autocomplete_team_name_admin_teams_path, input_html: {style: "width: 180px"}}

    field :name, :string, :text, {label: 'Name', default_value: '', condition: :like_full, input_html: {style: "width: 240px"}}
    field :uid, :string, :text, {label: 'UID', default_value: '', condition: :like_full, input_html: {style: "width: 200px"}}

  end

  def index
    @team_id = params[:team_id]

    if @team_id
      @team = Team.find(@team_id)
      @filter.set 'team_id', @team_id
      @filter.set 'team', @team.name
    end

    @items = Cluster.includes(:team, :hadoop_type).by_filter(@filter)
    #cluster_ids = Cluster.pluck(:id)#@items.ids

    # counts
    cluster_ids = @items.map(&:id)
    @count_invitations = Invitation.where(:cluster_id => cluster_ids).group(:cluster_id).count
    @count_nodes = Node.where(:cluster_id => cluster_ids).group(:cluster_id).count
    @count_containers = ClusterContainer.where(:cluster_id => cluster_ids).group(:cluster_id).count
    @count_applications = ClusterApplication.where(:cluster_id => cluster_ids).group(:cluster_id).count
    @count_services = ClusterService.where(:cluster_id => cluster_ids).group(:cluster_id).count


  end

  def show
    cluster_id = params[:id]

    if cluster_id.nil?
      raise 'Bad input'
    end

    #
    @item = Cluster.find(cluster_id)


    # consul info
    @info_consul = Gexcore::Consul::Service.get_cluster_data(@item)
    @locks_consul = Gexcore::Consul::Service.get_cluster_locks(cluster_id)


    # services
    @services_hadoop = Gexcore::ClusterServices::Service.get_service_list({cluster_id: @item.id, node_id: nil})



    # nodes
    #@nodes = Gexcore::Nodes::Service.get_nodes_for_cluster(@item.id)

    # containers
    @containers = @item.containers.master_containers.all

    # user token
    @user_token = Gexcore::AuthService.get_new_token(@item.team.primary_admin)
  end

  def run_provision_script
    @cmd_name = params[:cmd_name]

    @cluster = Cluster.find(params[:id])

    if @cmd_name=='create_cluster'
      @res = Gexcore::Clusters::Provision.provision_master_create_cluster(@cluster.hadoop_app)
    elsif @cmd_name=='fix_cluster_webproxy'
      @res = Gexcore::Clusters::Provision.fix_cluster_webproxy(@cluster)
    elsif @cmd_name=='remove_cluster'
      @res = Gexcore::Clusters::Provision.provision_master_remove_cluster(@cluster.hadoop_app)

    end


    respond_to do |format|
      format.html {      }
      format.json{        render :json=>@res      }
    end
  end

  def run_operation
    @cmd_name = params[:cmd_name]

    @cluster = Cluster.find(params[:id])

    if @cmd_name=='uninstall_cluster'
      # work
      #@res = Gexcore::Clusters::Service.delete_cluster_by_user(current_user, cluster_uid)
      ClusterDeleteWorker.perform_async(@cluster.id)
      @res = Gexcore::Response.res_data

    elsif @cmd_name=='remove_cluster'
      @res = Gexcore::Clusters::Service.remove_cluster(@cluster)
    else

    end


    respond_to do |format|
      format.html {      }
      format.json{        render :json=>@res      }
    end
  end

  def run_fix_status
    @cmd_name = params[:cmd_name]

    @cluster = Cluster.find(params[:id])

    if @cmd_name=='set_install_error'
      # work
      @cluster.set_install_error!
      @res = Gexcore::Response.res_data

    elsif @cmd_name=='set_uninstall_error'
      @cluster.set_uninstall_error!
      @res = Gexcore::Response.res_data
    else

    end


    respond_to do |format|
      format.html {      }
      format.json{        render :json=>@res      }
    end
  end

  def get_info_containers
    @cluster = Cluster.find(params[:id])

    @res = Gexcore::Clusters::Service.get_cluster_info_all(@cluster)

    respond_to do |format|
      format.html {

      }
      format.json{
        render :json=>@res
      }
    end
  end

  def cmd_test
    # run test
    @cmd = params[:cmd_name]

    @cluster = Cluster.find(params[:id])

    if @cmd=='test_cluster_master'
      @res = Gexcore::SystemTestService.test_cluster_master(@cluster)
    end


    respond_to do |format|
      format.html {      }
      format.json{        render :json=>@res      }
    end
  end

  def edit_notes
    @cluster = Cluster.find (params[:id]) if params[:id]
  end

  def update_notes
    #@user = User.find (session[:id]) if session[:id]
    @cluster = Cluster.find (params[:id]) if params[:id]

    @res = @cluster.update(note_params)
    respond_to do |format|
      if @res
        format.html {
          redirect_to admin_cluster_path(@cluster)
        }
        #format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :show }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit_options
    @cluster = Cluster.find (params[:id]) if params[:id]
  end

  def update_options
    #@user = User.find (session[:id]) if session[:id]
    @cluster = Cluster.find (params[:id]) if params[:id]

    @res = @cluster.update(options_params)
    respond_to do |format|
      if @res
        format.html {
          redirect_to admin_cluster_path(@cluster)
        }
        #format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :show }
        #format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def note_params
    params.require(:cluster).permit(:admin_notes)
  end

  def options_params
    params.require(:cluster).permit(:options)
  end

end
