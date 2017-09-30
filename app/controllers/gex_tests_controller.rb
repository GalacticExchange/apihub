class GexTestsController < InternalBaseController

  def clusters_number_of

    aws_clusters = Cluster.w_aws
    onprem_clusters = Cluster.w_onprem

    info = {
        aws: {
          total: aws_clusters.count,
          active: aws_clusters.w_active.count,
          not_removed: aws_clusters.w_not_deleted.count
        },
        onprem: {
            total: onprem_clusters.count,
            active: onprem_clusters.w_active.count,
            not_removed: onprem_clusters.w_not_deleted.count
        }
    }

    return_json Gexcore::Response.res_data({clusters_info: info})
  end

  def nodes_number_of

  end

end