module Gexcore::Nodes::Aws
  class Service < Gexcore::BaseService


    def self.add_node_to_cluster(cluster, opts={})
      res = response_init
      res.sysdata[:cluster_id] = cluster.id
      res.set_data

      #
      sysinfo = {}
      node_options = {
          aws_instance_type: opts[:instance_type],
          volume_size: opts[:disk_storage] || 100
      }
      extra_fields = {
          host_type_name: NodeHostType::DEDICATED,
          options: node_options,
          hadoop_app: (opts[:hadoop_app] || false)
      }

      res_create = Gexcore::Nodes::Service.create_node(nil, cluster, sysinfo, extra_fields)

      return res_create if res_create.error?

      #
      node = Node.get_by_id(res_create.data[:node_id])
      res.data[:node_id] = node.id

      # provision - aws instance
      #node.start_job_task('install', 'aws_instance')
      #NodeInstallAwsInstanceWorker.perform_async(node.id, get_env)

      res
    end



  end

end
