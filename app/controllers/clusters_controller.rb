class ClustersController < AccountBaseController
  layout "sidebar_view"
  before_action {@page_selected = "cluster"}

  autocomplete :cluster, :name



  def no_cluster
    @page_selected = "no_cluster"
    render :layout => 'application'
  end


  #
  def create
    # input
    @sysinfo = params[:systemInfo] || {}
    @cluster_data = build_cluster_create_data_from_params

    # do the job
    @res = Gexcore::Clusters::Service.create_cluster_by_user(current_user, @sysinfo, @cluster_data)

    respond_to do |format|
      if @res.success?
        format.html { redirect_to clusters_path, notice: 'Cluster created'  }
        format.json { return_json(@res) }
      else
        format.html {
          #todo unused

          #init_data_page_new
          #flash[:error] = "Something went wrong"
          #render :new, :aws
        }
        format.json { return_json(@res)  }
      end
    end
  end

  def build_cluster_create_data_from_params
    #
    data = {}

    data[:cluster_type] = ((params[:clusterType] || params[:cluster_params][:clusterType]) rescue nil) || ClusterType::DEFAULT_NAME
    data[:components] = params[:components]

    if data[:cluster_type]==ClusterType::ONPREM
      # hadoop type
      data[:hadoopType] = params[:hadoopType] || ClusterHadoopType::DEFAULT_NAME


      # params for cluster
      Cluster::OPTIONS.each do |p, opt_info|
        next unless params[p].present?
        #next unless opt_info[:set_from_user]

        v = params[p]

        if opt_info[:type]=='bool'
          v = (v.to_s=="1" || v.to_s=="true")
        end

        data[p] = v
      end

    elsif data[:cluster_type]==ClusterType::AWS
      data[:aws_region_id] = ((params[:awsRegion] || params[:cluster_params][:awsRegion]) rescue nil) || ''


      #
      key_id = params['awsKeysId'].to_i rescue nil

      if key_id
        # check user
        keys = current_user.keys.where(id: key_id).first

        if keys.nil?
          # todo
          return
        end

        data[:aws_key_id] = keys.get_cred('aws_key_id')
        data[:aws_secret_key] = keys.get_cred('aws_secret_key')
      else
        data[:aws_key_id] = params['awsKeyId'] || params['awsKeyID'] || ''
        data[:aws_secret_key] = params['awsSecretKey'] || ''
      end


    end

    data
  end


  def new
    init_data_page_new
    @res = Gexcore::Response.res_data({regions: @aws_regions.map{|r| r.to_hash} })
    respond_to do |format|
      format.html {      }
      format.json{   return_json(@res) }
    end
  end

  def wizard

  end


  def init_data_page_new
    @page_type='clusters'
    @page_selected = 'your_clusters'
    @aws_regions = AwsRegion.all

    @cluster ||= Cluster.new
  end


  ### public
  def show

    @name = params[:name]

    @cluster = Cluster.get_by_name(@name)
    @nodes_count = @cluster.nodes.w_not_deleted.count

    render :layout => 'application'
  end


  def index
    @page_type='clusters'
    @page_selected = 'your_clusters'
    #@items = current_user.team.clusters.w_not_deleted.order("id desc").limit(100)

    res = Gexcore::Clusters::Service.get_clusters_in_team_by_user(current_user, current_user.team)

    respond_to do |format|
      format.html{ }
      format.json{ return_json(res) }
    end
  end




  def info

    @apps = @current_cluster.applications.w_not_deleted.includes(:library_application).order("id desc").limit(100)
    @containers = @current_cluster.containers.w_not_deleted.includes(:application, :node).order("id desc").limit(100)
    @services = @current_cluster.services.w_not_deleted.order("id desc").limit(100)
    @nodes = @current_cluster.nodes.w_not_deleted.order("id desc").limit(100)

  end



  ### authorized
  def show_info

    check_current_cluster || return

    # work
    if current_user
      res = Gexcore::Clusters::Service.get_cluster_info_by_user(current_user, @current_cluster.uid)
    elsif @res_auth.data[:agent_node_id].present?
      res = Gexcore::Clusters::Service.get_cluster_info_by_agent(@res_auth.data[:agent_node_id], @current_cluster.uid)
    end

    return_json(res)
  end


  def components_list
    res  = Gexcore::Response.new
    res.set_data( components: Gexcore::Clusters::Components.get_components_hash)
    return_json(res)
  end


  def components
    check_current_cluster || return
    res = Gexcore::Clusters::Components.get_cluster_components_by_user(@current_cluster.uid, current_user)
    return_json(res)
  end


  ###
  def statistics
    raise 'deprecated'

    @page_selected = "stats"
    @items =[]
    @items_unsorted = @current_cluster.nodes.w_not_deleted.includes(:host_type).to_a

    @node_states = []


    @items_unsorted.each do |item|
      state_res = Gexcore::Nodes::Service.get_node_state_by_user(current_user, item)

      if state_res.success?
        node_state = state_res.data[:node][:state]
        if(node_state == 'running')
          @items.insert(0,item)
          @node_states.insert(0,node_state)
        else
          @items.push(item)
          @node_states.push(node_state)
        end
      end

    end

    #@res_data = Gexcore::Nodes::Service.list_nodes_with_performance(@cluster_id)
  end




  def destroy
    # input
    cluster_uid = params[:clusterId] || params[:clusterID]

    # work
    @res = Gexcore::Clusters::Service.delete_cluster_by_user(current_user, cluster_uid)

    return_json(@res)
  end

  def destroy_all
    # input
    cluster_uid = params[:clusterId] || params[:clusterID]

    # work
    @res = Gexcore::Clusters::Service.delete_cluster_all_by_user(current_user, cluster_uid)

    return_json(@res)
  end



  # clusters in a team
  def list_of_team
    # work
    res = Gexcore::Clusters::Service.get_clusters_in_team_by_user(current_user, current_user.team)

    return_json(res)
  end




  ### search clusters
  def search
    # q
    q = params['q'] || ''

    if q.nil? || q.blank?
      res = Gexcore::Response.res_error_badinput('', 'No input')
      return return_json(res)
    end

    # work
    res = Gexcore::ClustersSearchService.search(params, session)

    return_json(res)
  end


  ###
  def show_info_containers_all
    @cluster = Cluster.find(params[:id])

    @res = Gexcore::Clusters::Service.get_cluster_info_all(@cluster)

    respond_to do |format|
      format.html {      }
      format.json{        render :json=>@res      }
    end
  end


end

